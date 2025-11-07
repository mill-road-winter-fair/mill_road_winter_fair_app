import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  List<Map<String, dynamic>> filteredListings = [];
  bool isRefreshing = false;
  bool useFallbackSorting = false;
  final ScrollController _scrollController = ScrollController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<bool> detailsVisibilityList = List<bool>.filled(500, false);  // start with plenty enough to load all listings
  int firstNextListingIndex = -1;  // the first listing that hasn't passed its end date, when sorted by start date
  
  @override
  void initState() {
    debugPrint('FilteredListingsPageState initState() called');
    super.initState();
}

  void onTabVisible() {
    // This is called when user switches to this tab
    setState(() {
      detailsVisibilityList = List<bool>.filled(filteredListings.length, false);
    });
    if (firstNextListingIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Runs after the first layout and paint (when firstNextListingIndex has been found)
        if (firstNextListingIndex >= 0) {
          _itemScrollController.scrollTo(
            curve: Curves.linear,
            index: firstNextListingIndex,
            duration: const Duration(milliseconds: 300),
            alignment: 0,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    debugPrint('FilteredListingsPageState dispose() called');
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> navigateToMapAndGetDirections(String id, LatLng destinationCoordinates, http.Client client) async {
    // Remember the previous index to allow returning back
    previousIndex = homePageKey.currentState!.index;

    // Switch to map tab on the home page
    homePageKey.currentState?.setCurrentIndex(0);

    // Request the map page to show directions
    await mapPageKey.currentState?.getDirections(id, destinationCoordinates, false);
  }

  List<Map<String, dynamic>> _applySearchFilter(List<Map<String, dynamic>> allListings) {
    if (_searchQuery.isEmpty) return allListings;
    return allListings.where((listing) {
      final name = (listing['displayName'] ?? '').toString().toLowerCase();
      final secondary = (listing['secondaryType'] ?? '').toString().toLowerCase();
      final tertiary = (listing['tertiaryType'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || secondary.contains(_searchQuery) || tertiary.contains(_searchQuery);
    }).toList();
  }

  List<Map<String, dynamic>> _applySorting(List<Map<String, dynamic>> allListings) {
    try {
      if (allListings.isEmpty) throw Exception("No listings exist");

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
        allListings = allListings.map((listing) {
          LatLng destinationLatLng = stringToLatLng(listing['latLng']);
          final distance = asTheCrowFlies(currentLatLng!, destinationLatLng);
          return {...listing, 'approximateDistanceMetres': distance};
        }).toList();
      }

      // Sort based on preference
      if (preferredSortingMethod == SortingMethod.values[0] || useFallbackSorting == true) {
        // Sort by name
        allListings.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (preferredSortingMethod == SortingMethod.values[1]) {
        // Sort by distance to user (nearest first)
        allListings.sort((a, b) => a['approximateDistanceMetres'].compareTo(b['approximateDistanceMetres']));
      } else if (preferredSortingMethod == SortingMethod.values[2]) {
        // Sort by start time, if the start time is the same sort by name
        allListings.sort((a, b) {
          final timeCompare = a['startTime'].compareTo(b['startTime']);
          return timeCompare != 0 ? timeCompare : a['name'].compareTo(b['name']);
        });
      } else {
        // The only other option is location sorting
        allListings.sort((a, b) {
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

      return allListings;
    } on Exception catch (e) {
      debugPrint('Error sorting listings: $e');
      return allListings;
    } catch (e) {
      debugPrint('Unexpected error sorting listings: $e');
      return allListings;
    }
  }

  Future<void> refreshListings() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      listings = await fetchListings(http.Client());
      mapPageKey.currentState?.setMarkerLists();
      mapPageKey.currentState?.addAllVisibleMarkers();
      establishLocation();
    } finally {
      setState(() {
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

  void toggleDetailsRow(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      detailsVisibilityList[index] = !detailsVisibilityList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('FilteredListingsPageState build() called');
    final homePageState = context.findAncestorStateOfType<HomePageState>();
    // Show error if there are no listings
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
                    label: const Text('Refresh listings'),
                  ),
          ],
        ),
      );
    }

    // Step 1: Filter by primaryType (e.g. "Food", "Music", etc.)
    List<Map<String, dynamic>> primaryFiltered = [];
    if (widget.filterPrimaryType == 'Service') {
      primaryFiltered = listings.where((listing) => listing['primaryType'].startsWith('Service')).toList();
    } else {
      primaryFiltered = listings.where((listing) => listing['primaryType'] == widget.filterPrimaryType).toList();
    }

    // Step 2: Sort the filtered listings
    final sortedListings = _applySorting(primaryFiltered);

    // Step 3: Apply search filtering to that subset
    filteredListings = _applySearchFilter(sortedListings);

    // Step 4: If sorted by start date, find the first listing not to have ended
    firstNextListingIndex = -1;
    if (preferredSortingMethod == SortingMethod.values[2] && filteredListings.isNotEmpty) {
      int i = 0;
      do {
        if (!hasEventEnded(filteredListings[i]['endTime'])) firstNextListingIndex = i;
      } while (i++ < filteredListings.length && firstNextListingIndex < 0);
    }

    return RefreshIndicator(
      onRefresh: refreshListings,
      backgroundColor: Theme.of(context).colorScheme.primary,
      color: Theme.of(context).colorScheme.onPrimary,
      child: (filteredListings.isNotEmpty) ? ScrollablePositionedList.builder(
        itemCount: filteredListings.length + 1,
        itemScrollController: _itemScrollController,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
                height: 66,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceDim,
                ),
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isSearching
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ConstrainedBox(
                                    key: const ValueKey('searchBar'),
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 16),
                                    child: SearchBar(
                                      autoFocus: true,
                                      elevation: const WidgetStatePropertyAll(0),
                                      hintText: switch (widget.filterPrimaryType) {
                                        'Food' => 'Search food & drink vendors...',
                                        'Shopping' => 'Search market stalls...',
                                        'Music' => 'Search musical performances...',
                                        'Event' => 'Search events...',
                                        'Service' => 'Search services...',
                                        _ => 'Search listings...',
                                      },
                                      leading: const Icon(Icons.search),
                                      trailing: [
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              _isSearching = false;
                                              _searchQuery = '';
                                            });
                                          },
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value.toLowerCase();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if (!_isSearching) Expanded(child: _buildSortingDropdown(context)),
                                  SizedBox(
                                    height: 56,
                                    width: 56,
                                    child: FloatingActionButton(
                                      key: const ValueKey('searchFab'),
                                      heroTag: 'searchFab_${widget.filterPrimaryType}_page',
                                      backgroundColor: Theme.of(context).colorScheme.secondary,
                                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                      elevation: 0,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _isSearching = true;
                                        });
                                      },
                                      child: const Icon(Icons.search),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final listing = filteredListings[index - 1]; // since index=0 is the sort/search bar
              final approximateDistanceMetres = listing['approximateDistanceMetres'] ?? 0;
              final approximateDistance = 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}';
              LatLng destinationLatLng = stringToLatLng(listing['latLng']);

              return Column(
                children: [
                  SpecificListingInfoSheet(
                    title: listing['displayName'],
                    location: listing['secondaryType'],
                    subtitle: listing['tertiaryType'],
                    startTime: "${listing['startTime']}",
                    endTime: "${listing['endTime']}",
                    approxDistance: approximateDistance,
                    phoneNumber: (listing['phone'] != null) ? listing['phone'] : '',
                    website: (listing['website'] != null) ? listing['website'] : '',
                    email: (listing['email'] != null) ? listing['email'] : '',
                    description: (listing['description'] != null) ? listing['description'] : '',
                    detailsVisible: detailsVisibilityList[index - 1],
                    onDetailsTapped: () => toggleDetailsRow(index - 1),
                    onGetDirections: () {
                      if (homePageState != null) {
                        navigateToMapAndGetDirections(
                          listing['id'],
                          destinationLatLng,
                          http.Client(),
                        );
                      }
                    },
                  ),
                  // separator except after last item
                  if (index > 0 && index != filteredListings.length - 1)
                    SizedBox(height: 14, child: Divider(color: Theme.of(context).colorScheme.surfaceDim)),
                ],
              );
            }
          },
        ) : Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "No results found${_searchQuery.isNotEmpty ? ' for "$_searchQuery"' : ''}.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
    );
  }

  Widget _buildSortingDropdown(BuildContext context) {
    return Container(
      key: const ValueKey('dropdown'),
      height: 66,
      color: Theme.of(context).colorScheme.surfaceDim,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownMenu(
              initialSelection: preferredSortingMethod,
              width: MediaQuery.of(context).size.width * 0.6 + 40,
              label: const Text("Sort by", style: TextStyle(fontWeight: FontWeight.bold)),
              leadingIcon: const Icon(Icons.sort),
              textStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
                iconColor: Theme.of(context).colorScheme.onSecondary,
                suffixIconColor: Theme.of(context).colorScheme.onSecondary,
                prefixIconColor: Theme.of(context).colorScheme.onSecondary,
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
              dropdownMenuEntries: [
                if (locationPermission == LocationPermission.whileInUse || locationPermission == LocationPermission.always)
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
                if (widget.filterPrimaryType == 'Music' || widget.filterPrimaryType == 'Event')
                  DropdownMenuEntry(
                    value: SortingMethod.values[2],
                    label: "Start time",
                    leadingIcon: const Icon(Icons.alarm),
                  ),
              ],
              onSelected: sortingDropdownCallback,
            ),
          ),
        ],
      ),
    );
  }
}
