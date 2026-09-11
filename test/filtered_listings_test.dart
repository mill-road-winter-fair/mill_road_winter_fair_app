import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
}

Map<String, dynamic> testListing({
  required String id,
  required String title,
  String groupParent = 'FALSE',
  String food = 'FALSE',
  String shopping = 'FALSE',
  String performanceMusic = 'FALSE',
  String startTime = '10:30',
  String endTime = '16:30',
}) {
  return {
    'id': id,
    'visibleOnMap': 'TRUE',
    'cancelled': 'FALSE',
    'groupParent': groupParent,
    'brickAndMortar': 'FALSE',
    'emoji': '',
    'title': title,
    'subtitle': '',
    'groupID': '',
    'food': food,
    'shopping': shopping,
    'charityCommunityInfo': 'FALSE',
    'performanceMusic': performanceMusic,
    'performanceChildrens': 'FALSE',
    'performanceDance': 'FALSE',
    'performanceOther': 'FALSE',
    'visitExperience': 'FALSE',
    'service': 'FALSE',
    'location': 'Mill Road',
    'description': '',
    'email': '',
    'website': '',
    'phone': '',
    'latLng': '52.199174,0.140929',
    'imageURL': '',
    'startTime': startTime,
    'endTime': endTime,
  };
}

void main() {
  // We're on test
  onTest = true;

  // Mock location services and permissions and user settings once
  setUpAll(() async {
    locationServicesEnabled = true;
    locationPermission = LocationPermission.always;
    await loadSettings();
  });

  // Build widget tree helper
  Future<void> pumpFilteredListingsPage(
    WidgetTester tester,
    String category,
    List<Map<String, dynamic>> pageListings,
    List<String> favouriteIds, {
    String? subfilterCategory,
    DateTime? currentDateTime,
    bool resetState = false,
  }) async {
    if (resetState) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    listings = pageListings;
    favouriteListingKeys.value = favouriteIds.toSet();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilteredListingsPage(
            filterCategory: category,
            subfilterCategory: subfilterCategory,
            listings: pageListings,
            onTabSelected: (_) {},
            onSubfilterChange: (_) {},
            currentDateTime: currentDateTime,
          ),
        ),
      ),
    );
    await tester.pump();
    await settle(tester);
  }

  group('FilteredListingsPage', () {
    testWidgets('displays error text when fetchFilteredListings fails', (WidgetTester tester) async {
      // Define a test listing
      List<Map<String, dynamic>> listings = [];

      await pumpFilteredListingsPage(tester, 'all', listings, []);

      expect(find.text('Unable to retrieve listings'), findsOneWidget);
    });

    testWidgets('displays filtered listings correctly', (WidgetTester tester) async {
      // Override user location global
      currentLatLng = const LatLng(52.199174, 0.140929);
      // Define mock values
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'imageURL': '',
          'startTime': '10:30',
          'endTime': '16:30',
        },
        {
          'id': '2',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍣',
          'title': 'Sushi Squad',
          'subtitle': 'Sushi',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Implausible Avenue',
          'description': 'Cold rice',
          'email': '',
          'website': 'https://www.sushisquad.com',
          'phone': '',
          'latLng': '52.200063,0.139313',
          'imageURL': '',
          'startTime': '12:00',
          'endTime': '16:30',
        },
      ];

      await loadSettings();
      await pumpFilteredListingsPage(tester, 'all', listings, []);

      expect(find.text('🍩 '), findsOneWidget);
      expect(find.text('Glazed and Confused'), findsOneWidget);
      expect(find.text('Doughnuts'), findsOneWidget);
      expect(find.text('10:30—16:30'), findsOneWidget);
      expect(find.text('Gwydir St Car Park (approx. 206 m)'), findsOneWidget);
      expect(find.text('01223 111111'), findsNothing);  // as Details won't be open
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.text('Sushi Squad'), findsOneWidget);
      expect(find.text('Sushi'), findsOneWidget);
      expect(find.text('12:00—16:30'), findsOneWidget);
      expect(find.text('Implausible Avenue (approx. 197 m)'), findsOneWidget);
      // Count of walking icons is 3 because of the 1 in the sorting dropdown, plus 2 listings
      expect(find.byIcon(Icons.directions_walk), findsExactly(3));
      expect(find.byIcon(Icons.public), findsExactly(2));

    });

    testWidgets('different sorting methodologies change the order', (WidgetTester tester) async {
      await loadSettings();
      // Override user location global
      currentLatLng = const LatLng(52.199174, 0.140929);

      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'imageURL': '',
          'startTime': '10:30',
          'endTime': '16:30',
        },
        {
          'id': '2',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍣',
          'title': 'Sushi Squad',
          'subtitle': 'Sushi',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Implausible Avenue',
          'description': 'Cold rice',
          'email': '',
          'website': 'https://www.sushisquad.com',
          'phone': '',
          'latLng': '52.200063,0.139313',
          'imageURL': '',
          'startTime': '12:00',
          'endTime': '16:30',
        },
        {
          'id': '3',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍔',
          'title': 'Bite Club',
          'subtitle': 'Burgers',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Donkey Common',
          'description': 'Dead cattle',
          'email': '',
          'website': 'https://www.biteclub.com',
          'phone': '01223 333333',
          'latLng': '52.202313,0.131562',  // 968m
          'imageURL': '',
          'startTime': '14:00',
          'endTime': '16:30',
        },
      ];

      // Mock sorting preference is alphabetical
      preferredSortingMethod = SortingMethod.values[0];

      await pumpFilteredListingsPage(tester, 'all', listings, []);
      var filteredListingsPageState = tester.state(find.byType(FilteredListingsPage)) as FilteredListingsPageState;

      expect(filteredListingsPageState.filteredListings[0]['title'], 'Bite Club');
      expect(filteredListingsPageState.filteredListings[1]['title'], 'Glazed and Confused');
      expect(filteredListingsPageState.filteredListings[2]['title'], 'Sushi Squad');

      // Mock sorting preference is distance
      preferredSortingMethod = SortingMethod.values[1];

      await pumpFilteredListingsPage(tester, 'all', listings, []);
      filteredListingsPageState = tester.state(find.byType(FilteredListingsPage)) as FilteredListingsPageState;

      expect(filteredListingsPageState.filteredListings[0]['title'], 'Sushi Squad');
      expect(filteredListingsPageState.filteredListings[1]['title'], 'Glazed and Confused');
      expect(filteredListingsPageState.filteredListings[2]['title'], 'Bite Club');

      // Mock sorting preference is time - which for Food should sort by A-Z since time isn't allowed for sorting
      preferredSortingMethod = SortingMethod.values[2];

      await pumpFilteredListingsPage(tester, 'all', listings, []);
      filteredListingsPageState = tester.state(find.byType(FilteredListingsPage)) as FilteredListingsPageState;

      expect(filteredListingsPageState.filteredListings[0]['title'], 'Bite Club');
      expect(filteredListingsPageState.filteredListings[1]['title'], 'Glazed and Confused');
      expect(filteredListingsPageState.filteredListings[2]['title'], 'Sushi Squad');
    });

    testWidgets('tapping the sorting buttons changes preferred sorting method', (WidgetTester tester) async {
      await loadSettings();

      // Provide a listing so the page renders the sorting controls.
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performanceMusic': 'TRUE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'imageURL': '',
          'startTime': '10:30',
          'endTime': '16:30',
        },
      ];

      // Ensure the nearest sorting option is available in the menu
      locationPermission = LocationPermission.always;
      currentLatLng = const LatLng(52.199174, 0.140929);
      preferredSortingMethod = SortingMethod.values[0];

      await pumpFilteredListingsPage(tester, 'favourite', listings, ['1']);

      await tester.tap(find.byKey(const ValueKey('sortingdropdown')));
      await settle(tester);
      await tester.tap(find.text('Nearest').last);
      await settle(tester);

      expect(preferredSortingMethod, SortingMethod.values[1]);

      await tester.tap(find.byKey(const ValueKey('sortingdropdown')));
      await settle(tester);
      await tester.tap(find.text('Time').last);
      await settle(tester);

      expect(preferredSortingMethod, SortingMethod.values[2]);

      await tester.tap(find.byKey(const ValueKey('sortingdropdown')));
      await settle(tester);
      await tester.tap(find.text('Location (a–z)').last);
      await settle(tester);

      expect(preferredSortingMethod, SortingMethod.values[3]);

      await tester.tap(find.byKey(const ValueKey('sortingdropdown')));
      await settle(tester);
      await tester.tap(find.text('Name (a–z)').last);
      await settle(tester);

      expect(preferredSortingMethod, SortingMethod.values[0]);
    });

    testWidgets('change the preferred sorting method when location permission is denied', (WidgetTester tester) async {
      // Mock sorting preference is distance
      preferredSortingMethod = SortingMethod.values[1];

      // Location permission is denied
      locationPermission = LocationPermission.deniedForever;

      // Define mock values
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'imageURL': '',
          'startTime': '10:30',
          'endTime': '16:30',
        },
      ];

      await loadSettings();
      await pumpFilteredListingsPage(tester, 'all', listings, []);

      // Preferred sorting method should have been reset to 0 (alphabetical)
      expect(preferredSortingMethod, SortingMethod.values[0]);
    });

    testWidgets('use fallback sorting when location is unavailable, do not use it when location returns', (WidgetTester tester) async {
      await loadSettings();

      // Mock sorting preference is distance
      preferredSortingMethod = SortingMethod.values[1];

      // Location permission is granted
      locationPermission = LocationPermission.always;

      // Define mock values
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'imageURL': '',
          'startTime': '10:30',
          'endTime': '16:30',
        },
      ];

      // Mock location services are disabled
      locationServicesEnabled = false;

      await pumpFilteredListingsPage(tester, 'all', listings, []);

      // Obtain the state after mounting
      final filteredListingsPageState = tester.state(find.byType(FilteredListingsPage)) as FilteredListingsPageState;

      // Fallback sorting should be enabled
      expect(filteredListingsPageState.useFallbackSorting, true);

      // Preferred sorting method should be unchanged
      expect(preferredSortingMethod, SortingMethod.values[1]);

      // Mock location services are re-enabled
      locationServicesEnabled = true;
      // Mock location is available
      currentLatLng = const LatLng(52.199174, 0.140929);

      await pumpFilteredListingsPage(tester, 'all', listings, []);

      // Fallback sorting should be disabled
      expect(filteredListingsPageState.useFallbackSorting, false);

      // Preferred sorting method should be unchanged
      expect(preferredSortingMethod, SortingMethod.values[1]);

      // Mock location is now unavailable
      currentLatLng = null;

      await pumpFilteredListingsPage(tester, 'all', listings, []);

      // Fallback sorting should be enabled
      expect(filteredListingsPageState.useFallbackSorting, true);

      // Preferred sorting method should be unchanged
      expect(preferredSortingMethod, SortingMethod.values[1]);
    });

    testWidgets('FilteredListingsPage navigateToMapAndGetDirections function changes to MapPage', (WidgetTester tester) async {
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'imageURL': '',
          'startTime': '10:30',
          'endTime': '16:30',
        },
      ];

      await tester.pumpWidget(const MyApp());
      await settle(tester);

      expect(homePageKey.currentState, isNotNull, reason: 'HomePage should be mounted');
      expect(mapPageKey.currentState, isNotNull, reason: 'MapPage should be mounted');
      final homePageState = homePageKey.currentState!;
      final mapPageState = mapPageKey.currentState!;
      mapPageState.addAllVisibleMarkers();

      await tester.tap(find.text('Listings'));
      await settle(tester);
      expect(homePageState.index, 3);

      await tester.tap(find.byIcon(Icons.directions_walk).first);
      await settle(tester);

      expect(homePageState.index, 3);
    });

    testWidgets('FilteredListingsPage search filters results based on query (UI)', (WidgetTester tester) async {
      final sampleListings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍣',
          'title': 'Sushi Squad',
          'subtitle': 'Sushi',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Implausible Avenue',
          'description': 'Cold rice',
          'email': '',
          'website': 'https://www.sushisquad.com',
          'phone': '',
          'latLng': '52.200063,0.139313',
          'imageURL': '',
          'startTime': '12:00',
          'endTime': '16:30',
        },
        {
          'id': '2',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'imageURL': '',
          'startTime': '10:30',
          'endTime': '16:30',
        },
        {
          'id': '3',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍔',
          'title': 'Bite Club',
          'subtitle': 'Burgers',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Donkey Common',
          'description': 'Dead cattle',
          'email': '',
          'website': 'https://www.biteclub.com',
          'phone': '01223 333333',
          'latLng': '52.202313,0.131562',
          'imageURL': '',
          'startTime': '14:00',
          'endTime': '16:30',
        },
      ];

      // Set global listings so pages relying on the global don't show error/loading UI
      listings = sampleListings;

      // Start with a known current location so distance sorting works if required
      currentLatLng = const LatLng(52.199174, 0.140929);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilteredListingsPage(filterCategory: 'all', listings: sampleListings, onTabSelected: (_) {}, onSubfilterChange: (_) {}),
          ),
        ),
      );

      await settle(tester);

      // Initially all three listings should be visible
      expect(find.text('Sushi Squad'), findsOneWidget);
      expect(find.text('Glazed and Confused'), findsOneWidget);
      expect(find.text('Bite Club'), findsOneWidget);

      // Tap the search FAB to enter search mode
      final searchFab = find.byIcon(Icons.search);
      expect(searchFab, findsOneWidget);
      await tester.tap(searchFab);
      await settle(tester);

      // The SearchBar has a ValueKey('searchBar') on the ConstrainedBox; find the descendant TextField
      final searchBarBox = find.byKey(const ValueKey('searchBar'));
      expect(searchBarBox, findsOneWidget);

      final textFieldFinder = find.descendant(of: searchBarBox, matching: find.byType(TextField));
      expect(textFieldFinder, findsOneWidget);

      // Enter text that matches only Sushi Squad
      await tester.enterText(textFieldFinder, 'sushi');
      await settle(tester);

      // Only Sushi Squad should remain
      expect(find.text('Sushi Squad'), findsOneWidget);
      expect(find.text('Glazed and Confused'), findsNothing);
      expect(find.text('Bite Club'), findsNothing);

      // Clear the search using the close button in the SearchBar (Icon(Icons.close))
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      // All results should be back
      expect(find.text('Sushi Squad'), findsOneWidget);
      expect(find.text('Glazed and Confused'), findsOneWidget);
      expect(find.text('Bite Club'), findsOneWidget);
    });

    testWidgets('filters listings by page category, subcategory and favourites', (WidgetTester tester) async {
      final sampleListings = [
        testListing(id: 'food', title: 'Food stall', food: 'TRUE'),
        testListing(id: 'shop', title: 'Shopping stall', shopping: 'TRUE'),
        testListing(id: 'music', title: 'Music act', performanceMusic: 'TRUE'),
        testListing(
          id: 'parent',
          title: 'Group parent',
          groupParent: 'TRUE',
          food: 'TRUE',
        ),
      ];

      await pumpFilteredListingsPage(tester, 'food', sampleListings, [], resetState: true);
      var state = tester.state<FilteredListingsPageState>(find.byType(FilteredListingsPage));
      expect(state.filteredListings.map((listing) => listing['id']), ['food']);

      await pumpFilteredListingsPage(
        tester,
        'all',
        sampleListings,
        [],
        subfilterCategory: 'performanceMusic',
        resetState: true,
      );
      state = tester.state<FilteredListingsPageState>(find.byType(FilteredListingsPage));
      expect(state.filteredListings.map((listing) => listing['id']), ['music']);

      await pumpFilteredListingsPage(tester, 'favourite', sampleListings, ['shop'], resetState: true);
      state = tester.state<FilteredListingsPageState>(find.byType(FilteredListingsPage));
      expect(state.filteredListings.map((listing) => listing['id']), ['shop']);
    });

    testWidgets('only offers time sorting for performance and favourite pages', (WidgetTester tester) async {
      final sampleListings = [
        testListing(id: 'food', title: 'Food stall', food: 'TRUE'),
        testListing(id: 'music', title: 'Music act', performanceMusic: 'TRUE'),
      ];
      locationPermission = LocationPermission.always;
      currentLatLng = const LatLng(52.199174, 0.140929);
      preferredSortingMethod = SortingMethod.alphabetical;

      await pumpFilteredListingsPage(tester, 'food', sampleListings, [], resetState: true);
      await tester.tap(find.byKey(const ValueKey('sortingdropdown')));
      await settle(tester);
      expect(find.text('Nearest'), findsWidgets);
      expect(find.text('Location (a–z)'), findsWidgets);
      expect(find.text('Name (a–z)'), findsWidgets);
      expect(find.text('Time'), findsNothing);

      await pumpFilteredListingsPage(
        tester,
        'all',
        sampleListings,
        [],
        subfilterCategory: 'performanceMusic',
        resetState: true,
      );
      await tester.tap(find.byKey(const ValueKey('sortingdropdown')));
      await settle(tester);
      expect(find.text('Time'), findsWidgets);

      await pumpFilteredListingsPage(tester, 'favourite', sampleListings, ['food'], resetState: true);
      await tester.tap(find.byKey(const ValueKey('sortingdropdown')));
      await settle(tester);
      expect(find.text('Time'), findsWidgets);
    });

    testWidgets('scroll to now selects time sorting and finds the first current listing', (WidgetTester tester) async {
      final currentDateTime = DateTime(fairDate.year, fairDate.month, fairDate.day, 12, 15);
      final sampleListings = [
        testListing(
          id: 'future',
          title: 'Future act',
          performanceMusic: 'TRUE',
          startTime: '13:00',
          endTime: '14:00',
        ),
        testListing(
          id: 'past',
          title: 'Past act',
          performanceMusic: 'TRUE',
          startTime: '10:00',
          endTime: '11:00',
        ),
        testListing(
          id: 'current',
          title: 'Current act',
          performanceMusic: 'TRUE',
          startTime: '12:00',
          endTime: '13:00',
        ),
      ];
      preferredSortingMethod = SortingMethod.alphabetical;

      await pumpFilteredListingsPage(
        tester,
        'all',
        sampleListings,
        [],
        subfilterCategory: 'performanceMusic',
        currentDateTime: currentDateTime,
      );
      await tester.tap(find.byIcon(Icons.update));
      await settle(tester);

      final state = tester.state<FilteredListingsPageState>(find.byType(FilteredListingsPage));
      expect(preferredSortingMethod, SortingMethod.startTime);
      expect(state.filteredListings.map((listing) => listing['id']), ['past', 'current', 'future']);
      expect(state.firstNextListingIndex, 1);
    });

    testWidgets('hide past listings removes ended listings and can show them again', (WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('PonnamKarthik/fluttertoast'),
        (_) async => true,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('PonnamKarthik/fluttertoast'),
          null,
        );
      });
      final currentDateTime = DateTime(fairDate.year, fairDate.month, fairDate.day, 12, 15);
      final sampleListings = [
        testListing(
          id: 'past',
          title: 'Past act',
          performanceMusic: 'TRUE',
          startTime: '10:00',
          endTime: '11:00',
        ),
        testListing(
          id: 'current',
          title: 'Current act',
          performanceMusic: 'TRUE',
          startTime: '12:00',
          endTime: '13:00',
        ),
        testListing(
          id: 'future',
          title: 'Future act',
          performanceMusic: 'TRUE',
          startTime: '13:00',
          endTime: '14:00',
        ),
      ];

      await pumpFilteredListingsPage(
        tester,
        'all',
        sampleListings,
        [],
        subfilterCategory: 'performanceMusic',
        currentDateTime: currentDateTime,
      );
      expect(find.text('Past act'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.event_busy));
      await settle(tester);
      expect(find.text('Past act'), findsNothing);
      expect(find.text('Current act'), findsOneWidget);
      expect(find.text('Future act'), findsOneWidget);
      expect(find.byIcon(Icons.free_cancellation), findsOneWidget);

      await tester.tap(find.byIcon(Icons.free_cancellation));
      await settle(tester);
      expect(find.text('Past act'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
