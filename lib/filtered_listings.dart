// Dart SDK imports
import 'dart:async';
import 'dart:io';

// App imports
import 'package:mill_road_winter_fair_app/dependencies/date_time_provider.dart';
import 'package:mill_road_winter_fair_app/expanded_listing_reveal.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/listings_may_change_reminder.dart';

// Third-party imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilteredListingsPage extends StatefulWidget {
  final AnalyticsService analyticsService;
  final String filterCategory;
  final String? subfilterCategory;
  final List<Map<String, dynamic>> listings;
  final ValueChanged<int> onTabSelected;
  final Function(String?) onSubfilterChange;

  const FilteredListingsPage({
    required this.analyticsService,
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
  late DateTimeProvider _dateTimeProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dateTimeProvider = context.watch<DateTimeProvider>();
  }

  List<Map<String, dynamic>> filteredListings = [];
  bool isRefreshing = false;
  bool useFallbackSorting = false;
  final _expandedScrollBounds = ExpandedListingScrollBounds();
  final ItemScrollController itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();
  final ValueNotifier<bool> thumbVisible = ValueNotifier<bool>(false);
  Timer? _hideTimer; // for hiding scroll thumb when inactive i.e. iOS
  Timer? _searchAnalyticsTimer;
  bool _isSearching = false;
  bool _hidePastListings = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? detailsVisibleIndex; // which listing (if any) has details button selected
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
    _searchAnalyticsTimer?.cancel();
    itemPositionsListener.itemPositions.removeListener(() {});
    thumbVisible.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void onTabVisible() {
    // This is called when user switches to this tab
    setState(() {
      _searchAnalyticsTimer?.cancel();
      detailsVisibleIndex = null;
      _searchQuery = '';
      _isSearching = false;
    });
    if (itemScrollController.isAttached && filteredListings.isNotEmpty) itemScrollController.jumpTo(index: 0);
  }

  void _scheduleSearchAnalytics(String searchTerm) {
    _searchAnalyticsTimer?.cancel();
    final trimmedSearchTerm = searchTerm.trim();
    if (trimmedSearchTerm.isEmpty) return;
    _searchAnalyticsTimer = Timer(const Duration(milliseconds: 750), () {
      widget.analyticsService.logSearch(trimmedSearchTerm, searchArea: 'listings');
    });
  }

  String calculateAppBarTitle() {
    String appBarTitle = '';
    if (filterCategory == 'favourite') {
      appBarTitle += (appBarTitle.isEmpty) ? 'Favourites' : ' favourites';
    } else {
      appBarTitle += (appBarTitle.isEmpty) ? 'Listings' : ' listings';
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
        
        // The building/house number needs to be cut off before sorting, this regex targets numbers like '16', '1-2' and '27B'
        final leadingHouseNumber = RegExp(r'^\s*\d+[a-zA-Z]?(?:\s*[-–—]\s*\d+[a-zA-Z]?)?(?:\s+|$)');

        allListings.sort((a, b) {
          // 1. Compare by location, ignoring leading building/house numbers
          final locationA = (a['location'] as String).replaceFirst(leadingHouseNumber, '');
          final locationB = (b['location'] as String).replaceFirst(leadingHouseNumber, '');
          final locationCompare = locationA.compareTo(locationB);
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
      timetablePageKey.currentState?.thePreparedEvents = {}; // will trigger a re-prepare
      establishLocation();
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
    if (mounted) ListingUpdateNotifier.maybeShowNotice(context, analyticsService: widget.analyticsService);
  }

  void sortingDropdownCallback(SortingMethod? selectedValue) {
    HapticFeedback.selectionClick();
    widget.analyticsService.logButtonTapped('sorting_dropdown_option');
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
        widget.analyticsService.logPreferenceSet('sorting_method', selectedValue.name);
        setState(() {
          detailsVisibleIndex = null;
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
    detailsVisibleIndex = null;
    widget.analyticsService.logButtonTapped('listings_category_filter');
    widget.analyticsService.logPreferenceSet('listings_category', selectedValue ?? 'all');
    widget.onSubfilterChange.call(selectedValue);
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredSortingMethod', preferredSortingMethod.index);
    await prefs.setStringList('favouritesList', favouriteListingKeys.value.toList());
  }

  void toggleDetailsRow(int index) {
    setState(() {
      detailsVisibleIndex = (detailsVisibleIndex == null || detailsVisibleIndex != index) ? index : null;
    });
  }

  int findFirstNextListingIndex(List filteredListings) {
    for (int i = 0; i < filteredListings.length; i++) {
      if (!hasEventEnded(filteredListings[i]['endTime'], _dateTimeProvider)) {
        return i;
      }
    }
    return -1;
  }

  // Function to toggle the listing's presence in the list of favourites
  void favouriteOrNotListing(String listingID) {
    if (isListingFavourited(listingID)) {
      if (filterCategory == 'favourite' && detailsVisibleIndex != null && filteredListings[detailsVisibleIndex!]['id'] == listingID) detailsVisibleIndex = null;
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
      return FairScaffold(
        appBarTitle: calculateAppBarTitle(),
        currentTab: switch (filterCategory) { 'favourite' => 4, _ => 3 },
        onTabSelected: widget.onTabSelected,
        allowBack: false,
        analyticsService: widget.analyticsService,
        body: Center(
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.analyticsService.logButtonTapped('refresh_listings_from_error');
                        refreshListings();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh listings'),
                    ),
            ],
          ),
        ),
      );
    }

    isShowingJustPerformance = (widget.subfilterCategory != null && widget.subfilterCategory!.length > 11 && widget.subfilterCategory!.substring(0, 11) == 'performance');

    // Step 1a: Filter by category
    List<Map<String, dynamic>> categoryFiltered = [];
    if (filterCategory == 'all' || filterCategory == '') {
      categoryFiltered = listings.where((listing) => listing['groupParent'] == 'FALSE').toList();
    } else if (filterCategory == 'favourite') {
      categoryFiltered = listings.where((listing) => listing['groupParent'] == 'FALSE' && favouriteListingKeys.value.contains(listing['id'])).toList();
    } else {
      categoryFiltered = listings.where((listing) => listing['groupParent'] == 'FALSE' && listing[filterCategory] == 'TRUE').toList();
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
      numberOfVisibleListings = filteredListings.where((listing) => !hasEventEnded(listing['endTime'], _dateTimeProvider)).length;
    } else {
      numberOfVisibleListings = filteredListings.length;
    }
    int? firstVisibleIndex; // will be used to store the first listing that is actually visible

    final colorScheme = Theme.of(context).colorScheme;
    final appBarTheme = Theme.of(context).appBarTheme;
    final canScrollToNow = filterCategory == 'favourite' || isShowingJustPerformance;
    final canTogglePastListings = canScrollToNow || _hidePastListings;
    final nowOrSoonIconKey = GlobalKey();
    final hidePastIconKey = GlobalKey();
    final searchIconKey = GlobalKey();

    return FairScaffold(
      appBarTitle: calculateAppBarTitle(),
      currentTab: switch (filterCategory) { 'favourite' => 4, _ => 3 },
      onTabSelected: widget.onTabSelected,
      appBarActions: [
        IconButton(
          key: nowOrSoonIconKey,
          tooltip: 'Scroll to what is on now or starting soon',
          onLongPress: !canScrollToNow ? null : () => showMiniPopup(context, nowOrSoonIconKey, 'Tap to scroll to now to see what’s on or starting soon', analyticsService: widget.analyticsService),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (!canScrollToNow) {
              showMiniPopup(context, nowOrSoonIconKey, '‘Go to now’ is only available when showing just events or performances', fgColour: colorScheme.error, analyticsService: widget.analyticsService);
              return;
            }
            widget.analyticsService.logButtonTapped('listings_scroll_to_now');
            if (isItEventDay(_dateTimeProvider)) {
              if (firstNextListingIndex < 0) {
                // we may not be on Sort by Time, or the Fair may have recently started
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
                    numberOfVisibleListings = filteredListings.where((listing) => !hasEventEnded(listing['endTime'], _dateTimeProvider)).length;
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
              showMiniPopup(context, nowOrSoonIconKey, '‘Scroll to now’ is only available when the Fair is underway', fgColour: colorScheme.error, analyticsService: widget.analyticsService);
            }
          },
          icon: Icon(
            Icons.access_time,
            size: 24,
            color: (canScrollToNow && isItEventDay(_dateTimeProvider)) ? appBarTheme.foregroundColor : appBarTheme.foregroundColor?.withAlpha(130),
          ),
        ),
        IconButton(
          key: hidePastIconKey,
          tooltip: _hidePastListings ? 'Show past events and performances' : 'Hide past events and performances',
          onLongPress: !canTogglePastListings ? null : () => showMiniPopup(context, hidePastIconKey,
              (_hidePastListings) ? 'Tap to show all events and performances' : 'Tap to hide events and performances that have passed', analyticsService: widget.analyticsService),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (!canTogglePastListings) {
              showMiniPopup(context, hidePastIconKey, '‘Hide past listings’ is only available when showing just events or performances', fgColour: colorScheme.error, analyticsService: widget.analyticsService);
              return;
            }
            widget.analyticsService.logButtonTapped('listings_hide_past_toggle');
            if (isItEventDay(_dateTimeProvider)) {
              setState(() {
                _hidePastListings = !_hidePastListings;
                widget.analyticsService.logPreferenceSet('listings_hide_past', _hidePastListings.toString());
                numberOfVisibleListings = -1;
                firstVisibleIndex = null;
              });
              showInfoToast(context, (_hidePastListings) ? 'Hiding all events and performances that have passed' : 'Showing all events and performances');
            } else {
              showMiniPopup(context, hidePastIconKey, '‘Hide past listings’ is only available when the Fair is underway', fgColour: colorScheme.error, analyticsService: widget.analyticsService);
            }
          },
          icon: Icon(
            (_hidePastListings) ? Icons.free_cancellation : Icons.history_toggle_off,
            size:24,
            color: (canTogglePastListings && isItEventDay(_dateTimeProvider)) ? appBarTheme.foregroundColor : appBarTheme.foregroundColor?.withAlpha(130),
          ),
        ),
        _buildSortingDropdown(context, isShowingJustPerformance),
        _buildFilteringDropdown(context),
        IconButton(
          key: searchIconKey,
          tooltip: _isSearching ? 'Close listings search' : 'Search listings',
          color: colorScheme.onSecondary,
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.analyticsService.logButtonTapped('listings_search_toggle');
            setState(() {
              detailsVisibleIndex = null;
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchAnalyticsTimer?.cancel();
                _searchQuery = '';
                _searchController.text = '';
              }
            });
          },
          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll((_isSearching) ? Colors.white.withAlpha(30) : null)),
          icon: Icon(Icons.search, size: 26, color: appBarTheme.foregroundColor),
        ),
      ],
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: favouriteListingKeys,
        builder: (context, name, child) {
          return Column(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSearching
                  ? Container(
                    height: 52,
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceDim,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          key: const ValueKey('searchBar'),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 16, maxHeight: 36),
                          child: SearchBar(
                            autoFocus: true,
                            controller: _searchController,
                            elevation: const WidgetStatePropertyAll(0),
                            hintText: switch (widget.subfilterCategory) {
                              'food' => 'Search food & drink vendors...',
                              'shopping' => 'Search market stalls and shops...',
                              'performanceMusic' => 'Search musical performances...',
                              'performanceChildrens' => 'Search activities for children...',
                              'performanceDance' => 'Search dance performances...',
                              'performanceOther' => 'Search other performances...',
                              'charityCommunityInfo' => 'Search charity, community & info...',
                              'visitExperience' => 'Search visits & experiences...',
                              'service' => 'Search services...',
                              'business' => 'Search other local businesses...',
                              _ => 'Search all listings...',
                            },
                            leading: const Icon(Icons.search),
                            trailing: [
                              IconButton(
                                iconSize: 20,
                                tooltip: _searchQuery.isEmpty ? 'Close search' : 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  detailsVisibleIndex = null;
                                  widget.analyticsService.logButtonTapped('search_close');
                                  _searchAnalyticsTimer?.cancel();
                                  setState(() {
                                    if (_searchQuery.isEmpty) _isSearching = false; // first click clears field; second closes search
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              ),
                            ],
                            onChanged: (value) {
                              detailsVisibleIndex = null;
                              _scheduleSearchAnalytics(value);
                              setState(() {
                                _searchQuery = value.toLowerCase();
                                numberOfVisibleListings = -1;
                                firstVisibleIndex = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                )
              : SizedBox(height: 6),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refreshListings,
                backgroundColor: colorScheme.primary,
                color: colorScheme.onPrimary,
                child: Container(
                  color: colorScheme.surfaceDim,
                  child: LayoutBuilder(builder: (context, constraints) {
                    final trackHeight = constraints.maxHeight;
                    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                    final furnitureHeight = 98.0;
                    final contentHeight = constraints.maxHeight - (keyboardHeight - furnitureHeight).clamp(0.0, double.infinity);
                    return Stack(children: [
                      SizedBox(
                        height: contentHeight,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is UserScrollNotification ||
                                notification is ScrollUpdateNotification) {
                              _showThumb();
                            }
                            return false;
                          },
                          child: Semantics(
                            container: true,
                            explicitChildNodes: true,
                            button: detailsVisibleIndex != null,
                            label: detailsVisibleIndex == null ? null : 'Hide listing details',
                            child: GestureDetector(
                              onTap: detailsVisibleIndex == null
                                  ? null
                                  : () {
                                      final listing = filteredListings[detailsVisibleIndex!];
                                      widget.analyticsService.logButtonTapped('listing_details_dismiss', listingId: listing['id'], listingName: listing['title']);
                                      detailsVisibleIndex = null;
                                      HapticFeedback.lightImpact();
                                      setState(() {});
                                    },
                              child: ScrollablePositionedList.builder(
                                itemCount: filteredListings.length,
                                itemScrollController: itemScrollController,
                                itemPositionsListener: itemPositionsListener,
                                physics: ExpandedListingScrollPhysics(bounds: _expandedScrollBounds, parent: const AlwaysScrollableScrollPhysics()),
                                itemBuilder: (context, index) {
                                  final listing = filteredListings[index]; // since index=0 is the sort/search bar
                                  final approximateDistanceMetres = listing['approximateDistanceMetres'] ?? 0;
                                  final approximateDistance = '(~${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)} away)';
                                  final isFavourited = isListingFavourited(listing['id']);
                                  LatLng destinationLatLng = stringToLatLng(listing['latLng']);
                                  if (!_hidePastListings || !hasEventEnded(listing['endTime'], _dateTimeProvider)) {
                                    // if this is the first visible item, capture its index
                                    firstVisibleIndex ??= index;
                                  }
                                  return Column(
                                    key: ValueKey(listing['id']),
                                    children: [
                                      if (!_hidePastListings || !hasEventEnded(listing['endTime'], _dateTimeProvider)) ...[
                                        Container(
                                          width: constraints.maxWidth - 10,
                                          decoration: BoxDecoration(
                                            color: (isFavourited) ? colorScheme.onSecondaryFixed : colorScheme.onPrimary,
                                            border: Border.all(color: colorScheme.primary, width: 0.5),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
                                          ),
                                          child: SpecificListingInfoSheet(
                                            scrollBounds: _expandedScrollBounds,
                                            listingId: listing['id'],
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
                                            detailsVisible: (detailsVisibleIndex == null) ? false : (detailsVisibleIndex == index) ? true : null,
                                            listingFavourited: isFavourited,
                                            listingAlerted: alertsStore.alertExists(listing['id']),
                                            onDetailsTapped: () => toggleDetailsRow(index),
                                            onFavouriteTapped: () => favouriteOrNotListing(listing['id']),
                                            onGetDirections: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => MapPage(
                                                    listings: listings,
                                                    onTabSelected: (_) => {},
                                                    destinationId: listing['id'],
                                                    destinationLatLng: destinationLatLng,
                                                    analyticsService: widget.analyticsService,
                                                  )
                                                )
                                              );
                                            },
                                            onAlertTapped: () async {
                                              HapticFeedback.lightImpact();
                                              await toggleListingAlert(listing['id'], alertNoticePeriod, context);
                                              setState(() { });
                                            },
                                            analyticsService: widget.analyticsService,
                                            inDialog: false,
                                            colorScheme: colorScheme,
                                          )
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
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
                                    onVerticalDragUpdate: detailsVisibleIndex != null ? null : (details) {
                                      _showThumb();
                                      final localDy = details.localPosition.dy.clamp(0.0, trackHeight);
                                      final fraction = (localDy / trackHeight).clamp(0.0, 1.0);
                                      final targetIndex =
                                          (fraction * numberOfVisibleListings).floor().clamp(0, numberOfVisibleListings - 1) + firstVisibleIndex!;
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
                      (filteredListings.isEmpty || (_hidePastListings && findFirstNextListingIndex(filteredListings) < 0))
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(24.0),
                                alignment: Alignment.center,
                                child: Text(
                                    style: TextStyle(color: colorScheme.tertiary, fontSize: 16, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    'No'
                                    '${widget.subfilterCategory != null ? ' ${subfilterCategoryLabels[widget.subfilterCategory]!.label}' : ''}'
                                    ' listings'
                                    '${_searchQuery.isNotEmpty ? ' containing ‘$_searchQuery’' : ''}'
                                    '${filterCategory == 'favourite' ? ' in your favourites' : ' found'}.'
                                    '${(widget.subfilterCategory != null && _isSearching) ? '\n\nTap the magnifying glass to close search, then ‘Show’ to change what type of listings are displayed.' : ''}'
                                    '${(widget.subfilterCategory != null && !_isSearching) ? '\n\nUse ‘Show’ above to change what type of listings are displayed.' : ''}'
                                    '${filterCategory == 'favourite' ? '\n\nTap ‘Listings’ below to display all (not just favourite) listings.' : ''}'
                                    '${_searchQuery.isNotEmpty ? '\n\nTap ‘X’ in the bar above to clear your search.' : ''}'),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ]);
                  }),
                ),
              ),
            ),
          ]);
        }),
      analyticsService: widget.analyticsService,
    );
  }

  Widget _buildSortingDropdown(BuildContext context, bool isPerformance) {
    final colorScheme = Theme.of(context).colorScheme;
    final menuEntryStyle = TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant);
    final selectedMenuEntryStyle = menuEntryStyle.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold);
    final effectiveSortingMethod = useFallbackSorting ? SortingMethod.alphabetical : preferredSortingMethod;
    return MenuAnchor(
      key: ValueKey('sortingdropdown'),
      menuChildren: [
        MenuItemButton(
          onPressed: null,
          child: Text("Sort by", style: menuEntryStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        if (locationPermission == LocationPermission.whileInUse || locationPermission == LocationPermission.always)
          MenuItemButton(
            onPressed: () => sortingDropdownCallback(SortingMethod.nearest),
            leadingIcon: Icon(Icons.directions_walk, size: 20, color: (effectiveSortingMethod == SortingMethod.nearest) ? colorScheme.primary : colorScheme.onSurfaceVariant),
            child: Text("Nearest", style: (effectiveSortingMethod == SortingMethod.nearest) ? selectedMenuEntryStyle : menuEntryStyle),
          ),
        MenuItemButton(
          onPressed: () => sortingDropdownCallback(SortingMethod.location),
          leadingIcon: Icon(Icons.signpost, size: 20, color: (effectiveSortingMethod == SortingMethod.location) ? colorScheme.primary : colorScheme.onSurfaceVariant),
          child: Text("Location (a–z)", style: (effectiveSortingMethod == SortingMethod.location) ? selectedMenuEntryStyle : menuEntryStyle),
        ),
        MenuItemButton(
          onPressed: () => sortingDropdownCallback(SortingMethod.alphabetical),
          leadingIcon: Icon(Icons.sort_by_alpha, size: 20, color: (effectiveSortingMethod == SortingMethod.alphabetical) ? colorScheme.primary : colorScheme.onSurfaceVariant),
          child: Text("Name (a–z)", style: (effectiveSortingMethod == SortingMethod.alphabetical) ? selectedMenuEntryStyle : menuEntryStyle),
        ),
        if (isPerformance || filterCategory == 'favourite')
          MenuItemButton(
          onPressed: () => sortingDropdownCallback(SortingMethod.startTime),
            leadingIcon: Icon(Icons.alarm, size: 20, color: (effectiveSortingMethod == SortingMethod.startTime) ? colorScheme.primary : colorScheme.onSurfaceVariant),
            child: Text("Start time", style: (effectiveSortingMethod == SortingMethod.startTime) ? selectedMenuEntryStyle : menuEntryStyle),
          ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          icon: const Icon(Icons.sort),
          tooltip: 'Choose how to sort listings',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }


  Widget _buildFilteringDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final menuEntryStyle = TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant);
    final selectedMenuEntryStyle = menuEntryStyle.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold);
    return MenuAnchor(
      key: ValueKey('filterdropdown'),
      menuChildren: [
        MenuItemButton(
          onPressed: null,
          child: Text("Show", style: menuEntryStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        MenuItemButton(
          onPressed: () => filteringDropdownCallback(null),
          leadingIcon: Icon(Icons.all_inclusive, size: 20, color: (widget.subfilterCategory == null) ? colorScheme.primary : colorScheme.onSurfaceVariant),
          child: Text("Everything", style: (widget.subfilterCategory == null) ? selectedMenuEntryStyle : menuEntryStyle),
        ),
        ...subfilterCategoryLabels.entries.map((e) {
          return MenuItemButton(
            onPressed: () => filteringDropdownCallback(e.key),
            leadingIcon: Icon(e.value.iconData, size: 20, color: (widget.subfilterCategory == e.key) ? colorScheme.primary : colorScheme.onSurfaceVariant),
            child: Text(e.value.label, style: (widget.subfilterCategory == e.key) ? selectedMenuEntryStyle : menuEntryStyle),
          );
        })
      ],
      builder: (context, controller, child) {
        return IconButton(
          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll((widget.subfilterCategory != null) ? Colors.white.withAlpha(30) : null)),
          icon: const Icon(Icons.filter_alt, size: 26),
          tooltip: 'Choose which types of listings to show',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }

}
