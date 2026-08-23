import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

class FilteredListingsPage extends StatefulWidget {
  final String filterCategory;
  final String? subfilterCategory;
  final List<Map<String, dynamic>> listings;
  final ValueChanged<int> onTabSelected;
  final Function(String?) onSubfilterChange;

  const FilteredListingsPage({
    required this.filterCategory,
    this.subfilterCategory,
    required this.onSubfilterChange,
    required this.listings,
    required this.onTabSelected,
    super.key,
  });

  @override
  State<FilteredListingsPage> createState() => FilteredListingsPageState();
}

class FilteredListingsPageState extends State<FilteredListingsPage> {
  List<Map<String, dynamic>> filteredListings = [];
  bool isRefreshing = false;
  bool useFallbackSorting = false;
  final ItemScrollController itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();
  final ValueNotifier<bool> thumbVisible = ValueNotifier<bool>(false);
  Timer? _hideTimer; // for hiding scroll thumb when inactive i.e. iOS
  bool _isSearching = false;
  bool _hidePastListings = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<bool> detailsVisibilityList = List<bool>.filled(500, false); // start with plenty enough to load all listings
  int firstNextListingIndex = -1; // the first listing that hasn't passed its end time, when sorted by start time
  int numberOfVisibleListings = -1;
  late String filterCategory;
  bool isShowingJustPerformance = false; // when selected subcategory starts with 'Performance'

  @override
  void initState() {
    debugPrint('FilteredListingsPageState initState() called');
    super.initState();
    filterCategory = widget.filterCategory;
  }

  @override
  void dispose() {
    debugPrint('FilteredListingsPageState dispose() called');
    _hideTimer?.cancel();
    itemPositionsListener.itemPositions.removeListener(() {});
    thumbVisible.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void onTabVisible() {
    // This is called when user switches to this tab
    setState(() {
      detailsVisibilityList = List<bool>.filled(500, false);
      _searchQuery = '';
      _isSearching = false;
    });
    if (itemScrollController.isAttached && filteredListings.isNotEmpty) itemScrollController.jumpTo(index: 0);
  }

  String calculateAppBarTitle() {
    String appBarTitle = '';
    if (widget.subfilterCategory != null) appBarTitle += 'Filtered';
    if (filterCategory == 'favourite') {
      appBarTitle += (appBarTitle.isEmpty) ? 'Favourite listings' : ' favourites'; // 'filtered favourite listings' doesn't fit!
    } else {
      appBarTitle += (appBarTitle.isEmpty) ? 'All Listings' : ' listings';
    }
    return appBarTitle;
  }

  List<Map<String, dynamic>> _applySearchFilter(List<Map<String, dynamic>> allListings) {
    if (_searchQuery.isEmpty) return allListings;
    return allListings.where((listing) {
      final name = (listing['title'] ?? '').toString().toLowerCase();
      final location = (listing['location'] ?? '').toString().toLowerCase();
      final subtitle = (listing['subtitle'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || location.contains(_searchQuery) || subtitle.contains(_searchQuery);
    }).toList();
  }

  List<Map<String, dynamic>> _applySorting(List<Map<String, dynamic>> allListings) {
    try {
      if (allListings.isEmpty) throw Exception("No listings exist");

      if ((locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) &&
          preferredSortingMethod == SortingMethod.nearest) {
        // User prefers distance sorting but has disabled location permissions, change their preferred sorting method
        preferredSortingMethod = SortingMethod.alphabetical;
      }

      if ((locationServicesEnabled == false || currentLatLng == null) && preferredSortingMethod == SortingMethod.nearest) {
        // User prefers distance sorting but their location services are disabled or we cannot get the user's location, use fallback (a-z) sorting but don't change their saved preferences
        useFallbackSorting = true;
      } else {
        useFallbackSorting = false;
      }

      if ((locationPermission == LocationPermission.whileInUse || locationPermission == LocationPermission.always) &&
          locationServicesEnabled == true &&
          useFallbackSorting == false &&
          currentLatLng != null) {
        // Add distance to each listing
        allListings = allListings.map((listing) {
          LatLng destinationLatLng = stringToLatLng(listing['latLng']);
          final distance = asTheCrowFlies(currentLatLng!, destinationLatLng);
          return {...listing, 'approximateDistanceMetres': distance};
        }).toList();
      }

      if ((preferredSortingMethod == SortingMethod.startTime && !(isShowingJustPerformance || filterCategory == 'favourite'))) {
        // User prefers time sorting but this isn't allowed; use fallback (a-z) sorting but don't change their saved preferences
        // NB separate to the above test since we can still add the distances
        useFallbackSorting = true;
      }

      // Sort based on preference
      if (preferredSortingMethod == SortingMethod.alphabetical || useFallbackSorting == true) {
        // Sort by name; if this is the same sort by end time
        allListings.sort((a, b) {
          final nameCompare = a['title'].compareTo(b['title']);
          return nameCompare != 0 ? nameCompare : a['endTime'].compareTo(b['endTime']);
        });
      } else if (preferredSortingMethod == SortingMethod.nearest) {
        // Sort by distance to user (nearest first); if the distance is the same sort by start time
        allListings.sort((a, b) {
            final distanceCompare = a['approximateDistanceMetres'].compareTo(b['approximateDistanceMetres']);
            return distanceCompare != 0 ? distanceCompare : a['startTime'].compareTo(b['startTime']);
        });
      } else if (preferredSortingMethod == SortingMethod.startTime) {
        if (currentLatLng != null) {
          // Sort by end time; if this is the same sort by nearest
          allListings.sort((a, b) {
            final timeCompare = a['endTime'].compareTo(b['endTime']);
            return timeCompare != 0 ? timeCompare : a['approximateDistanceMetres'].compareTo(b['approximateDistanceMetres']);
          });
        } else {
          // Sort by end time; if this is the same sort by location
          allListings.sort((a, b) {
            final timeCompare = a['endTime'].compareTo(b['endTime']);
            return timeCompare != 0 ? timeCompare : a['location'].compareTo(b['location']);
          });
        }
      } else {
        // The only other option is location sorting
        allListings.sort((a, b) {
          // 1. Compare by location
          final locationCompare = a['location'].compareTo(b['location']);
          if (locationCompare != 0) return locationCompare;

          // 2. If location is the same, compare by startTime
          final timeCompare = a['startTime'].compareTo(b['startTime']);
          if (timeCompare != 0) return timeCompare;

          // 3. If startTime is also the same, compare by name
          return a['title'].compareTo(b['title']);
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
      mapPageKey.currentState?.setVisibleMarkerLists();
      if (navigationInProgress == false) {
        mapPageKey.currentState?.addAllVisibleMarkers();
      }
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
      if (selectedValue == SortingMethod.nearest && currentLatLng == null) {
        Fluttertoast.showToast(
          msg: 'Location services and permissions are required to determine distances',
          gravity: ToastGravity.CENTER,
          backgroundColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          fontSize: 16,
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 4,
        );
      } else {
        setState(() {
          preferredSortingMethod = selectedValue;
        });
        if (itemScrollController.isAttached) {
          itemScrollController.scrollTo(
            curve: Curves.linear,
            index: 0,
            duration: const Duration(milliseconds: 300),
            alignment: 0,
          );
        }
        _saveSettings();
      }
    }
  }

  void filteringDropdownCallback(String? selectedValue) {
    HapticFeedback.selectionClick();
    widget.onSubfilterChange.call(selectedValue);
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredSortingMethod', preferredSortingMethod.index);
    await prefs.setStringList('favouritesList', favouriteListingKeys.value.toList());
  }

  void toggleDetailsRow(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      detailsVisibilityList[index] = !detailsVisibilityList[index];
    });
  }

  int findFirstNextListingIndex(List filteredListings) {
    for (int i = 0; i < filteredListings.length; i++) {
      if (!hasEventEnded(filteredListings[i]['endTime'])) {
        return i;
      }
    }
    return -1;
  }

  // Function to toggle the listing's presence in the list of favourites
  void favouriteOrNotListing(String listingID) {
    if (isListingFavourited(listingID)) {
      favouriteListingKeys.value = {...favouriteListingKeys.value}..remove(listingID);
    } else {
      favouriteListingKeys.value = {...favouriteListingKeys.value, listingID};
    }
    setState(() {});
    _saveSettings();
  }

  // Function to determine if the listing has been added to favourites
  bool isListingFavourited(String listingID) {
    return favouriteListingKeys.value.contains(listingID);
  }

  // Support for hiding the scroll thumb when not active, for iOS
  void _showThumb() {
    thumbVisible.value = true;
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && Platform.isIOS) thumbVisible.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('FilteredListingsPageState build() called with filterCategory=$filterCategory and subfilterCategory=${widget.subfilterCategory}');
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

    isShowingJustPerformance = (widget.subfilterCategory != null && widget.subfilterCategory!.length > 11 && widget.subfilterCategory!.substring(0,11) == 'performance');

    // Step 1a: Filter by category
    List<Map<String, dynamic>> categoryFiltered = [];
    if (filterCategory == 'all' || filterCategory == '') {
      categoryFiltered = listings.where((listing) => 
        listing['groupParent'] == 'FALSE'
      ).toList();
    } else if (filterCategory == 'favourite') {
      categoryFiltered = listings.where((listing) => 
        listing['groupParent'] == 'FALSE'
        && favouriteListingKeys.value.contains(listing['id'])
      ).toList();
    } else {
      categoryFiltered = listings.where((listing) => 
        listing['groupParent'] == 'FALSE'
        && listing[filterCategory] == 'TRUE'
      ).toList();
    }

    // Step 1b: Filter by subcategory (e.g. "Food", "Music", etc.)
    List<Map<String, dynamic>> subCategoryFiltered = [];
    if (widget.subfilterCategory == null) {
      subCategoryFiltered = categoryFiltered;
    } else {
      subCategoryFiltered = categoryFiltered.where((listing) => listing[widget.subfilterCategory] == 'TRUE').toList();
    }

    // Step 2: Sort the filtered listings
    final sortedListings = _applySorting(subCategoryFiltered);

    // Step 3: Apply search filtering to that subset
    filteredListings = _applySearchFilter(sortedListings);

    // Step 4: If sorted by start time, find the first listing not to have ended
    firstNextListingIndex = -1;
    if (preferredSortingMethod == SortingMethod.startTime) {
      if (filteredListings.isNotEmpty) {
        firstNextListingIndex = findFirstNextListingIndex(filteredListings);
      }
    }

    // Step 5: Calculate number of visible listings for scroll thumb
    if (_hidePastListings) {
      numberOfVisibleListings = filteredListings.where((listing) => !hasEventEnded(listing['endTime'])).length;
    } else {
      numberOfVisibleListings = filteredListings.length;
    }
    int? firstVisibleIndex; // will be used to store the first listing that is actually visible

    final colorScheme = Theme.of(context).colorScheme;
    final appBarTheme = Theme.of(context).appBarTheme;
    final nowOrSoonIconKey = GlobalKey();
    final hidePastIconKey = GlobalKey();
    final searchIconKey = GlobalKey();

    return FairScaffold(
      appBarTitle: calculateAppBarTitle(),
      currentTab: switch (filterCategory) {'favourite' => 4, _ => 3},
      onTabSelected: widget.onTabSelected,
      appBarActions: [
        if (filterCategory == 'favourite' || isShowingJustPerformance)
          IconButton(
            key: nowOrSoonIconKey,
            onLongPress: () => showMiniPopup(context, nowOrSoonIconKey, 'Tap to scroll to now to see what’s on or starting soon'),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (isItEventDay()) {
                if (firstNextListingIndex < 0) {  // we may not be on Sort by Time, or the Fair may have recently started
                  SortingMethod savedSortingMethod = preferredSortingMethod;
                  preferredSortingMethod = SortingMethod.startTime;
                  List<Map<String, dynamic>> sortedListingsTemp = _applySorting(subCategoryFiltered);
                  List<Map<String, dynamic>> filteredListingsTemp = _applySearchFilter(sortedListingsTemp);
                  firstNextListingIndex = findFirstNextListingIndex(filteredListingsTemp);
                  if (firstNextListingIndex < 0) {
                    preferredSortingMethod = savedSortingMethod; // restore if not found a listing to scroll to
                  } else {
                    filteredListings = filteredListingsTemp;
                    if (_hidePastListings) {
                      numberOfVisibleListings = filteredListings.where((listing) => !hasEventEnded(listing['endTime'])).length;
                    } else {
                      numberOfVisibleListings = filteredListings.length;
                    }
                    setState(() {
                      preferredSortingMethod = SortingMethod.startTime;
                    });
                  }
                }
                if (firstNextListingIndex >= 0) {
                  itemScrollController.scrollTo(
                    curve: Curves.linear,
                    index: firstNextListingIndex,
                    duration: const Duration(milliseconds: 300),
                    alignment: 0,
                  );
                } else {
                  itemScrollController.scrollTo(
                    curve: Curves.linear,
                    index: filteredListings.length - 1,
                    duration: const Duration(milliseconds: 300),
                    alignment: 0,
                  );
                }
              } else {
                showMiniPopup(context, nowOrSoonIconKey, '‘Scroll to now’ is only available when the Fair is underway', colorScheme.error);
              }
            },
            icon: Icon(
              Icons.update,
              color: (isItEventDay()) ? appBarTheme.foregroundColor : appBarTheme.foregroundColor?.withAlpha(130),
            ),
          ),
        if (isShowingJustPerformance || filterCategory == 'favourite')
          IconButton(
            key: hidePastIconKey,
            onLongPress: () => showMiniPopup(context, hidePastIconKey, (_hidePastListings) ? 'Tap to show all events and performances' : 'Tap to hide events and performances that have passed'),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (isItEventDay()) {
                setState(() {
                  _hidePastListings = !_hidePastListings;
                  numberOfVisibleListings = -1;
                  firstVisibleIndex = null;
                });
                Fluttertoast.showToast(
                  msg: (_hidePastListings) ? 'Hiding all events and performances that have passed' : 'Showing all events and performances',
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  fontSize: 16,
                  toastLength: Toast.LENGTH_SHORT,
                  timeInSecForIosWeb: 2,
                );
              } else {
                showMiniPopup(context, hidePastIconKey, '‘Hide past listings’ is only available when the Fair is underway', colorScheme.error);
              }
            },
            icon: Icon(
              (_hidePastListings) ? Icons.free_cancellation : Icons.event_busy, 
              color: (isItEventDay()) ? appBarTheme.foregroundColor : appBarTheme.foregroundColor?.withAlpha(130),
            ),
          ),
          IconButton(
            key: searchIconKey,
            color: colorScheme.onSecondary,
            onLongPress: () => showMiniPopup(context, searchIconKey, (_isSearching) ? 'Tap to close the search bar and cancel your search' : 'Tap to open the search bar'),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.text = '';
                }
              });
            },
            icon: Icon((_isSearching) ? Icons.search_off : Icons.search, size: 26, color: appBarTheme.foregroundColor),
          ),
      ],
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: favouriteListingKeys,
        builder: (context, name, child) {
          return Column(
            children: [
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSearching ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          key: const ValueKey('searchBar'),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 16, maxHeight: 36),
                          child: SearchBar(
                            autoFocus: true,
                            controller: _searchController,
                            elevation: const WidgetStatePropertyAll(0),
                            hintText: switch (filterCategory) {
                              'all' => 'Search all listings...',
                              'food' => 'Search food & drink vendors...',
                              'shopping' => 'Search market stalls...',
                              'performanceMusic' => 'Search musical performances...',
                              'performanceChildrens' => 'Search children’s activities...',
                              'performanceDance' => 'Search dance performances...',
                              'performanceOther' => 'Search other performances...',
                              'charityCommunityInfo' => 'Search charity, community & info...',
                              'visitExperience' => 'Search visits & experiences...',
                              'service' => 'Search services...',
                              'favourite' => 'Search favourite listings...',
                              _ => 'Search listings...',
                            },
                            leading: const Icon(Icons.search),
                            trailing: [
                              IconButton(
                                iconSize: 20,
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    if (_searchQuery.isEmpty) _isSearching = false; // first click clears field; second closes search
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                                numberOfVisibleListings = -1;
                                firstVisibleIndex = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ) : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: (MediaQuery.of(context).size.width - 12) * 0.58, maxHeight: 48),
                          child: _buildFilteringDropdown(context),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: (MediaQuery.of(context).size.width - 12) * 0.42, maxHeight: 48),
                          child: _buildSortingDropdown(context, isShowingJustPerformance),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refreshListings,
                  backgroundColor: colorScheme.primary,
                  color: colorScheme.onPrimary,
                  child: Container(// ensure the Stack has a defined height
                    color: colorScheme.primary.withAlpha(20),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final trackHeight = constraints.maxHeight;
                      return Stack(children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is UserScrollNotification || notification is ScrollUpdateNotification) {
                              _showThumb();
                            }
                            return false;
                          },
                          child: ScrollablePositionedList.builder(
                            itemCount: filteredListings.length,
                            itemScrollController: itemScrollController,
                            itemPositionsListener: itemPositionsListener,
                            itemBuilder: (context, index) {
                              final listing = filteredListings[index]; // since index=0 is the sort/search bar
                              final approximateDistanceMetres = listing['approximateDistanceMetres'] ?? 0;
                              final approximateDistance = '(approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)})';
                              LatLng destinationLatLng = stringToLatLng(listing['latLng']);
                              if (!_hidePastListings || !hasEventEnded(listing['endTime'])) firstVisibleIndex ??= index; // if this is the first visible item, capture its index
                              return Column(
                                children: [
                                  if (!_hidePastListings || !hasEventEnded(listing['endTime'])) Container(
                                    width: constraints.maxWidth - 10,
                                    decoration: BoxDecoration(
                                      color: colorScheme.onPrimary,
                                      border: Border.all(color: colorScheme.primary, width: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
                                    ),
                                    child: SpecificListingInfoSheet(
                                      cancelled: listing['cancelled'] == 'TRUE' ? true : false,
                                      brickAndMortar: listing['brickAndMortar'] == 'TRUE' ? true : false,
                                      emoji: listing['emoji'] ?? '',
                                      title: listing['title'] ?? '',
                                      subtitle: listing['subtitle'] ?? '',
                                      location: listing['location'],
                                      description: listing['description'] ?? '',
                                      email: listing['email'] ?? '',
                                      website: listing['website'] ?? '',
                                      phoneNumber: listing['phone'] ?? '',
                                      imageURL: listing['imageURL'] ?? '',
                                      startTime: "${listing['startTime']}",
                                      endTime: "${listing['endTime']}",
                                      approxDistance: approximateDistance,
                                      detailsVisible: detailsVisibilityList[index],
                                      listingFavourited: isListingFavourited(listing['id']),
                                      onDetailsTapped: () => toggleDetailsRow(index),
                                      onFavouriteTapped: () => favouriteOrNotListing(listing['id']),
                                      onGetDirections: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => MapPage(
                                          listings: listings, 
                                          onTabSelected: (_) => {}, 
                                          destinationId: listing['id'],
                                          destinationLatLng: destinationLatLng
                                        )));
                                      },
                                      inDialog: false,
                                    )
                                  ),
                                  // separator except after last item
                                  if (index != filteredListings.length - 1 && (!_hidePastListings || !hasEventEnded(listing['endTime']))) SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ),
                        ValueListenableBuilder<Iterable<ItemPosition>>(
                          valueListenable: itemPositionsListener.itemPositions,
                          builder: (context, positions, _) {
                            if (positions.isEmpty || firstVisibleIndex == null || numberOfVisibleListings == 0) {
                              return const SizedBox.shrink();
                            }
                            final visiblePositions = positions.where((p) {
                              return p.index >= firstVisibleIndex! && p.index < firstVisibleIndex! + numberOfVisibleListings;
                            });
                            if (visiblePositions.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final indices = visiblePositions.map((p) => p.index);
                            final minIndex = indices.reduce((a, b) => a < b ? a : b);
                            final maxIndex = indices.reduce((a, b) => a > b ? a : b);
                            final minIndexRelative = minIndex - firstVisibleIndex!;
                            final visibleFraction = ((maxIndex - minIndex + 1) / numberOfVisibleListings).clamp(0.02, 1.0);
                            final thumbHeight = (trackHeight * visibleFraction).clamp(24.0, trackHeight);
                            final thumbTop = (minIndexRelative / numberOfVisibleListings) * trackHeight;
                            return ValueListenableBuilder<bool>(
                              valueListenable: thumbVisible,
                              builder: (context, visible, _) {
                                return Positioned(
                                  right: 3,
                                  top: thumbTop,
                                  width: 4,
                                  height: thumbHeight,
                                  child: AnimatedOpacity(
                                    opacity: visible ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                    child: GestureDetector(
                                      onVerticalDragStart: (_) => _showThumb(),
                                      onVerticalDragUpdate: (details) {
                                        _showThumb();
                                        final localDy = details.localPosition.dy.clamp(0.0, trackHeight);
                                        final fraction = (localDy / trackHeight).clamp(0.0, 1.0);
                                        final targetIndex = (fraction * numberOfVisibleListings).floor().clamp(0, numberOfVisibleListings - 1) + firstVisibleIndex!;
                                        itemScrollController.scrollTo(
                                          index: targetIndex,
                                          duration: const Duration(milliseconds: 120),
                                        );
                                      },
                                      child: Container(
                                        width: 2,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        (filteredListings.isEmpty || (_hidePastListings && findFirstNextListingIndex(filteredListings) < 0)) ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(24.0), alignment: Alignment.center,
                            child: Text(style: TextStyle(color: colorScheme.tertiary, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center,
                                'No'
                                '${widget.subfilterCategory != null ? ' ${subfilterCategoryLabels[widget.subfilterCategory]!.label}' : ''}'
                                ' listings'
                                '${_searchQuery.isNotEmpty ? ' containing ‘$_searchQuery’' : ''}'
                                '${filterCategory == 'favourite' ? ' in your favourites' : ' found'}.'
                                '${(widget.subfilterCategory != null && _isSearching) ? '\n\nTap the magnifying glass to close search, then ‘Show’ to change what type of listings are displayed.' : ''}'
                                '${(widget.subfilterCategory != null && !_isSearching) ? '\n\nUse ‘Show’ above to change what type of listings are displayed.' : ''}'
                                '${filterCategory == 'favourite' ? '\n\nTap ‘Listings’ below to display all (not just favourite) listings.' : ''}'
                                '${_searchQuery.isNotEmpty ? '\n\nTap ‘X’ in the bar above to clear your search.' : ''}'
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
                      ]);
                    }
                  ),
                  ),
                ),
              ),
            ]
          );
        }
      )
    );
  }

  Widget _buildSortingDropdown(BuildContext context, bool isPerformance) {
    final colorScheme = Theme.of(context).colorScheme;
    final dropdownStyle = ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13)));
    return Container(
      key: const ValueKey('sortingdropdown'),
      color: colorScheme.surfaceDim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: DropdownMenu(
          initialSelection: useFallbackSorting ? SortingMethod.alphabetical : preferredSortingMethod,
          label: Text("Sort by", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          leadingIcon: const Icon(Icons.sort),
          textStyle: TextStyle(color: colorScheme.onSecondary, fontSize: 12, height: 1.0),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: colorScheme.secondary,
            iconColor: colorScheme.onSecondary,
            suffixIconColor: colorScheme.onSecondary,
            prefixIconColor: colorScheme.onSecondary,
            labelStyle: TextStyle(color: colorScheme.onSecondary),
            isDense: true,
            visualDensity: const VisualDensity(horizontal: -4),
            contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
            constraints: BoxConstraints(maxHeight: 40),
            suffixIconConstraints: BoxConstraints(minWidth: 30, maxWidth: 30),
          ),
          dropdownMenuEntries: [
            if (locationPermission == LocationPermission.whileInUse || locationPermission == LocationPermission.always)
              DropdownMenuEntry(
                value: SortingMethod.nearest,
                label: "Nearest",
                style: dropdownStyle,
                leadingIcon: const Icon(Icons.directions_walk, size: 20),
              ),
            DropdownMenuEntry(
              value: SortingMethod.location,
              label: "Location (a–z)",
              style: dropdownStyle,
              leadingIcon: const Icon(Icons.signpost, size: 20),
            ),
            DropdownMenuEntry(
              value: SortingMethod.alphabetical,
              label: "Name (a–z)",
              style: dropdownStyle,
              leadingIcon: const Icon(Icons.sort_by_alpha, size: 20),
            ),
              if (isPerformance || filterCategory == 'favourite')
              DropdownMenuEntry(
                value: SortingMethod.startTime,
                label: "Time",
                style: dropdownStyle,
                leadingIcon: const Icon(Icons.alarm, size: 20),
              ),
          ],
          onSelected: sortingDropdownCallback,
        ),
      ),
    );
  }


  Widget _buildFilteringDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dropdownStyle = ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13)));
    return Container(
      key: const ValueKey('filteringdropdown'),
      color: colorScheme.surfaceDim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: DropdownMenu<String?>(
          initialSelection: widget.subfilterCategory,
          //width: (MediaQuery.of(context).size.width - 24) / 2,
          label: const Text("Show", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          leadingIcon: const Icon(Icons.filter_alt),
          textStyle: TextStyle(color: colorScheme.onSecondary, fontSize: 12, height: 1.0),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: colorScheme.secondary,
            iconColor: colorScheme.onSecondary,
            suffixIconColor: colorScheme.onSecondary,
            prefixIconColor: colorScheme.onSecondary,
            labelStyle: TextStyle(color: colorScheme.onSecondary),
            isDense: true,
            visualDensity: const VisualDensity(horizontal: -4),
            contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
            constraints: BoxConstraints(maxHeight: 40),
            suffixIconConstraints: BoxConstraints(minWidth: 30, maxWidth: 30),
          ),
          dropdownMenuEntries: [
            DropdownMenuEntry(
              value: null,
              label: "All",
              style: dropdownStyle,
              leadingIcon: const Icon(Icons.all_inclusive, size: 20),
            ),
            ...subfilterCategoryLabels.entries.map((e) {
              return DropdownMenuEntry(
                value: e.key,
                label: e.value.label,
                style: dropdownStyle,
                leadingIcon: Icon(e.value.iconData, size: 20),
              );
            })
          ],
          onSelected: filteringDropdownCallback,
        ),
      ),
    );
  }

}
