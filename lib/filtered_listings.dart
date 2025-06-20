import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheet.dart';
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
  State<FilteredListingsPage> createState() => _FilteredListingsPageState();
}

class _FilteredListingsPageState extends State<FilteredListingsPage> {
  // ignore: unused_field
  late Future<List> _sortedListings;
  bool isRefreshing = false;

  @override
  void initState() {
    _sortedListings = sortListings();
    super.initState();
  }

  Future<List> sortListings() async {
    try {
      if (listings.isEmpty) {
        throw Exception("No listings exist");
      }

      if (currentLatLng != null) {
        // Add approximate distance to each listing
        listings = listings.map((listing) {
          LatLng destinationLatLng = stringToLatLng(listing['latLng']);
          final distance = asTheCrowFlies(currentLatLng, destinationLatLng);
          return {...listing, 'approximateDistanceMetres': distance};
        }).toList();
      }

      if (preferredSortingMethod == SortingMethod.values[0]) {
        // Sort listings by approximate distance
        listings.sort((a, b) {
          int distanceA = a['approximateDistanceMetres'];
          int distanceB = b['approximateDistanceMetres'];
          return distanceA.compareTo(distanceB);
        });
        return listings;
      } else {
        // Sort listings by name
        listings.sort((a, b) {
          String nameA = a['name'];
          String nameB = b['name'];
          return nameA.compareTo(nameB);
        });
        return listings;
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
      mapPageKey.currentState?.addAllMarkers(false);
      establishLocation();
    } finally {
      setState(() {
        _sortedListings = sortListings();
        isRefreshing = false;
      });
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
          ));
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
          child: Column(
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[350]!, width: 2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text("Sort by: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          Flexible(
                            flex: 8,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(3, 1, 3, 1),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: preferredSortingMethod == SortingMethod.values[0]
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.secondary,
                                    foregroundColor: preferredSortingMethod == SortingMethod.values[0]
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.onSecondary),
                                child: const Text('Nearest'),
                                onPressed: () {
                                  setState(() {
                                    preferredSortingMethod = SortingMethod.values[0];
                                  });
                                  _saveSettings();
                                },
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 8,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(3, 1, 3, 1),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: preferredSortingMethod == SortingMethod.values[1]
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.secondary,
                                    foregroundColor: preferredSortingMethod == SortingMethod.values[1]
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.onSecondary),
                                child: const Text('A-Z'),
                                onPressed: () {
                                  setState(() {
                                    preferredSortingMethod = SortingMethod.values[1];
                                  });
                                  _saveSettings();
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )),
              Expanded(
                flex: 24,
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  separatorBuilder: (BuildContext context, int index) => Divider(color: Colors.grey[350]),
                  itemCount: filteredListings.length,
                  itemBuilder: (context, index) {
                    final listing = filteredListings[index];
                    final approximateDistanceMetres = listing['approximateDistanceMetres'] ?? 0;
                    final approximateDistance = 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}';
                    LatLng destinationLatLng = stringToLatLng(listing['latLng']);
                    return ListingInfoSheet(
                      title: listing['displayName'],
                      categories: "${listing['secondaryType']} • ${listing['tertiaryType']}",
                      openingTimes: "${listing['startTime']} - ${listing['endTime']}",
                      approxDistance: approximateDistance,
                      phoneNumber: listing['phone'],
                      website: listing['website'],
                      onGetDirections: () => {
                        if (homePageState != null)
                          {
                            homePageState.navigateToMapAndGetDirections(listing['id'], destinationLatLng, http.Client()),
                          }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
