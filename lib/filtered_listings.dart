import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/string_to_latlng.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilteredListingsPage extends StatefulWidget {
  final String filterPrimaryType;
  final List<Map<String, dynamic>> listings;

  const FilteredListingsPage({
    required this.filterPrimaryType,
    required this.listings,
    super.key,
  });

  @override
  State<FilteredListingsPage> createState() => FilteredListingsPageState();
}

class FilteredListingsPageState extends State<FilteredListingsPage> {
  // ignore: unused_field
  late Future<List> _sortedListings;
  bool isRefreshing = false;
  bool useFallbackSorting = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _sortedListings = sortListings();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up
    super.dispose();
  }

  Future<List> sortListings() async {
    try {
      if (listings.isEmpty) throw Exception("No listings exist");

      if ((locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) &&
          preferredSortingMethod == SortingMethod.values[1]) {
        // User prefers distance sorting but has disabled location permissions, change their preferred sorting method
        preferredSortingMethod = SortingMethod.values[0];
      }

      if ((locationServicesEnabled == false || currentLatLng == null) && preferredSortingMethod == SortingMethod.values[1]) {
        // User prefers distance sorting but their location services are disabled or we cannot get the user's location, use fallback (a-z) sorting but don't change their saved preferences
        useFallbackSorting = true;
      } else {
        useFallbackSorting = false;
      }

      if ((locationPermission == LocationPermission.whileInUse || locationPermission == LocationPermission.always) &&
          locationServicesEnabled == true &&
          useFallbackSorting == false) {
        // Add distance to each listing
        listings = listings.map((listing) {
          LatLng destinationLatLng = stringToLatLng(listing['latLng']);
          final distance = asTheCrowFlies(currentLatLng, destinationLatLng);
          return {...listing, 'approximateDistanceMetres': distance};
        }).toList();
      }

      // Sort based on preference
      if (preferredSortingMethod == SortingMethod.values[0] || useFallbackSorting == true) {
        // Sort by name
        listings.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (preferredSortingMethod == SortingMethod.values[1]) {
        // Sort by distance to user (nearest first)
        listings.sort((a, b) => a['approximateDistanceMetres'].compareTo(b['approximateDistanceMetres']));
      } else if (preferredSortingMethod == SortingMethod.values[2]) {
        // Sort by start time, if the start time is the same sort by name
        listings.sort((a, b) {
          final timeCompare = a['startTime'].compareTo(b['startTime']);
          return timeCompare != 0 ? timeCompare : a['name'].compareTo(b['name']);
        });
      } else {
        // The only other option is location sorting
        listings.sort((a, b) {
          // 1. Compare by location (secondaryType)
          final locationCompare = a['secondaryType'].compareTo(b['secondaryType']);
          if (locationCompare != 0) return locationCompare;

          // 2. If location is the same, compare by startTime
          final timeCompare = a['startTime'].compareTo(b['startTime']);
          if (timeCompare != 0) return timeCompare;

          // 3. If startTime is also the same, compare by name
          return a['name'].compareTo(b['name']);
        });
      }

      return listings;
    } on Exception catch (e) {
      debugPrint('Error sorting listings: $e');
      return listings;
    } catch (e) {
      return Future.error('Error sorting listings: $e');
    }
  }

  Future<void> refreshListings() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      listings = await fetchListings(http.Client());
      mapPageKey.currentState?.setMarkerLists();
      mapPageKey.currentState?.addAllVisibleMarkers(false);
      establishLocation();
    } finally {
      setState(() {
        _sortedListings = sortListings();
        isRefreshing = false;
      });
    }
  }

  void sortingDropdownCallback(SortingMethod? selectedValue) {
    HapticFeedback.selectionClick();
    if (selectedValue is SortingMethod) {
      if (selectedValue == SortingMethod.values[1] && currentLatLng == null) {
        Fluttertoast.showToast(
          msg: 'Location services and permissions are required to determine distances',
          gravity: ToastGravity.CENTER,
          backgroundColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          fontSize: 16,
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        setState(() {
          preferredSortingMethod = selectedValue;
        });
        _saveSettings();
      }
    }
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredSortingMethod', preferredSortingMethod.index);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sortedListings = sortListings(),
      initialData: listings,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              textAlign: TextAlign.center,
              style: TextStyle(
                backgroundColor: Theme.of(context).colorScheme.error,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          );
        }

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Unable to retrieve listings",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                isRefreshing
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: refreshListings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Listings'),
                      ),
              ],
            ),
          );
        }

        final allListings = snapshot.data as List;

        // Filter the listings based on the primaryType
        final filteredListings = allListings.where((listing) => listing['primaryType'] == widget.filterPrimaryType).toList();

        final homePageState = context.findAncestorStateOfType<HomePageState>();

        return RefreshIndicator(
          onRefresh: refreshListings,
          backgroundColor: Theme.of(context).colorScheme.primary,
          color: Theme.of(context).colorScheme.onPrimary,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true, // or false if you prefer "show on scroll"
            thickness: 4,
            radius: const Radius.circular(8),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Dropdown header that scrolls away
                SliverToBoxAdapter(
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceDim,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 66),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: DropdownMenu(
                              initialSelection: preferredSortingMethod,
                              width: MediaQuery.of(context).size.width * 0.6,
                              label: const Text(
                                "Sort by",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              leadingIcon: const Icon(Icons.sort),
                              inputDecorationTheme: InputDecorationTheme(
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.secondary,
                              ),
                              dropdownMenuEntries: [
                                DropdownMenuEntry(
                                  value: SortingMethod.values[1],
                                  label: "Nearest",
                                  leadingIcon: const Icon(Icons.directions_walk),
                                ),
                                DropdownMenuEntry(
                                  value: SortingMethod.values[3],
                                  label: "Location (a-z)",
                                  leadingIcon: const Icon(Icons.signpost),
                                ),
                                DropdownMenuEntry(
                                  value: SortingMethod.values[0],
                                  label: "Name (a-z)",
                                  leadingIcon: const Icon(Icons.sort_by_alpha),
                                ),
                                DropdownMenuEntry(
                                  value: SortingMethod.values[2],
                                  label: "Time",
                                  leadingIcon: const Icon(Icons.alarm),
                                ),
                              ],
                              onSelected: sortingDropdownCallback,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Listings list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = filteredListings[index];
                      final approximateDistanceMetres = listing['approximateDistanceMetres'] ?? 0;
                      final approximateDistance = 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}';
                      LatLng destinationLatLng = stringToLatLng(listing['latLng']);

                      return Column(
                        children: [
                          SpecificListingInfoSheet(
                            title: listing['displayName'],
                            categories: "${listing['secondaryType']} • ${listing['tertiaryType']}",
                            openingTimes: "${listing['startTime']} - ${listing['endTime']}",
                            approxDistance: approximateDistance,
                            phoneNumber: listing['phone'],
                            website: listing['website'],
                            onGetDirections: () {
                              if (homePageState != null) {
                                homePageState.navigateToMapAndGetDirections(
                                  listing['id'],
                                  destinationLatLng,
                                  http.Client(),
                                );
                              }
                            },
                          ),
                          // separator except after last item
                          if (index != filteredListings.length - 1) Divider(color: Colors.grey[350]),
                        ],
                      );
                    },
                    childCount: filteredListings.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
