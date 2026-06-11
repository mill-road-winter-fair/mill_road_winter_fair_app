import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

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
    List<Map<String, dynamic>> listings,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilteredListingsPage(
            filterCategory: category,
            listings: listings,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  group('FilteredListingsPage', () {
    testWidgets('displays error text when fetchFilteredListings fails', (WidgetTester tester) async {
      // Define a test listing
      List<Map<String, dynamic>> listings = [];

      await pumpFilteredListingsPage(tester, 'Food', listings);

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
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'category': 'Food',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'startTime': '10:30',
          'endTime': '16:30',
        },
        {
          'id': '2',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'emoji': '🍣',
          'title': 'Sushi Squad',
          'subtitle': 'Sushi',
          'groupID': '',
          'category': 'Food',
          'location': 'Implausible Avenue',
          'description': 'Cold rice',
          'email': '',
          'website': 'https://www.sushisquad.com',
          'phone': '',
          'latLng': '52.200063,0.139313',
          'startTime': '12:00',
          'endTime': '16:30',
        },
      ];

      await loadSettings();
      await pumpFilteredListingsPage(tester, 'Food', listings);

      expect(find.text('🍩 Glazed and Confused'), findsOneWidget);
      expect(find.text('Doughnuts'), findsOneWidget);
      expect(find.text('10:30—16:30'), findsOneWidget);
      expect(find.text('Gwydir St Car Park (approx. 206 m)'), findsOneWidget);
      expect(find.text('01223 111111'), findsNothing);  // as Details won't be open
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.text('🍣 Sushi Squad'), findsOneWidget);
      expect(find.text('Sushi'), findsOneWidget);
      expect(find.text('12:00—16:30'), findsOneWidget);
      expect(find.text('Implausible Avenue (approx. 197 m)'), findsOneWidget);
      // Count of walking icons is 3 because of the 1 in the sorting dropdown, plus 2 listings
      expect(find.byIcon(Icons.directions_walk), findsExactly(3));
      expect(find.byIcon(Icons.public), findsExactly(2));

      final dividerFinder = find.byWidgetPredicate((widget) => widget is Divider);
      expect(dividerFinder, findsWidgets);
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
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'category': 'Food',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'startTime': '10:30',
          'endTime': '16:30',
        },
        {
          'id': '2',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'emoji': '🍣',
          'title': 'Sushi Squad',
          'subtitle': 'Sushi',
          'groupID': '',
          'category': 'Food',
          'location': 'Implausible Avenue',
          'description': 'Cold rice',
          'email': '',
          'website': 'https://www.sushisquad.com',
          'phone': '',
          'latLng': '52.200063,0.139313',
          'startTime': '12:00',
          'endTime': '16:30',
        },
        {
          'id': '3',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'emoji': '🍔',
          'title': 'Bite Club',
          'subtitle': 'Burgers',
          'groupID': '',
          'category': 'Food',
          'location': 'Donkey Common',
          'description': 'Dead cattle',
          'email': '',
          'website': 'https://www.biteclub.com',
          'phone': '01223 333333',
          'latLng': '52.202313,0.131562',  // 968m
          'startTime': '14:00',
          'endTime': '16:30',
        },
      ];

      // Mock sorting preference is alphabetical
      preferredSortingMethod = SortingMethod.values[0];

      await pumpFilteredListingsPage(tester, 'Food', listings);
      var filteredListingsPageState = tester.state(find.byType(FilteredListingsPage)) as FilteredListingsPageState;

      expect(filteredListingsPageState.filteredListings[0]['title'], 'Bite Club');
      expect(filteredListingsPageState.filteredListings[1]['title'], 'Glazed and Confused');
      expect(filteredListingsPageState.filteredListings[2]['title'], 'Sushi Squad');

      // Mock sorting preference is distance
      preferredSortingMethod = SortingMethod.values[1];

      await pumpFilteredListingsPage(tester, 'Food', listings);
      filteredListingsPageState = tester.state(find.byType(FilteredListingsPage)) as FilteredListingsPageState;

      expect(filteredListingsPageState.filteredListings[0]['title'], 'Sushi Squad');
      expect(filteredListingsPageState.filteredListings[1]['title'], 'Glazed and Confused');
      expect(filteredListingsPageState.filteredListings[2]['title'], 'Bite Club');

      // Mock sorting preference is time - which for Food should sort by A-Z since time isn't allowed for sorting
      preferredSortingMethod = SortingMethod.values[2];

      await pumpFilteredListingsPage(tester, 'Food', listings);
      filteredListingsPageState = tester.state(find.byType(FilteredListingsPage)) as FilteredListingsPageState;

      expect(filteredListingsPageState.filteredListings[0]['title'], 'Bite Club');
      expect(filteredListingsPageState.filteredListings[1]['title'], 'Glazed and Confused');
      expect(filteredListingsPageState.filteredListings[2]['title'], 'Sushi Squad');
    });

    testWidgets('tapping the sorting buttons changes preferred sorting method', (WidgetTester tester) async {
      await loadSettings();
      await pumpFilteredListingsPage(tester, 'Music', listings);

      await tester.tap(find.byType(DropdownMenu<SortingMethod>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nearest').last);
      await tester.pumpAndSettle();

      expect(preferredSortingMethod, SortingMethod.values[1]);

      await tester.tap(find.byType(DropdownMenu<SortingMethod>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Time').last);
      await tester.pumpAndSettle();

      expect(preferredSortingMethod, SortingMethod.values[2]);

      await tester.tap(find.byType(DropdownMenu<SortingMethod>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Location (a-z)').last);
      await tester.pumpAndSettle();

      expect(preferredSortingMethod, SortingMethod.values[3]);

      await tester.tap(find.byType(DropdownMenu<SortingMethod>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name (a-z)').last);
      await tester.pumpAndSettle();

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
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'category': 'Food',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'startTime': '10:30',
          'endTime': '16:30',
        },
      ];

      await loadSettings();
      await pumpFilteredListingsPage(tester, 'Food', listings);

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
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'category': 'Food',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'startTime': '10:30',
          'endTime': '16:30',
        },
      ];

      // Mock location services are disabled
      locationServicesEnabled = false;

      await pumpFilteredListingsPage(tester, 'Food', listings);

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

      await pumpFilteredListingsPage(tester, 'Food', listings);

      // Fallback sorting should be disabled
      expect(filteredListingsPageState.useFallbackSorting, false);

      // Preferred sorting method should be unchanged
      expect(preferredSortingMethod, SortingMethod.values[1]);

      // Mock location is now unavailable
      currentLatLng = null;

      await pumpFilteredListingsPage(tester, 'Food', listings);

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
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'category': 'Food',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'startTime': '10:30',
          'endTime': '16:30',
        },
      ];

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Obtain the state after mounting
      final homePageState = tester.state(find.byType(HomePage)) as HomePageState;
      final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;
      mapPageState.addAllVisibleMarkers();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(homePageState.index, 1);

      await tester.tap(find.text('Directions'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 0);
    });

    testWidgets('FilteredListingsPage search filters results based on query (UI)', (WidgetTester tester) async {
      final sampleListings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'emoji': '🍣',
          'title': 'Sushi Squad',
          'subtitle': 'Sushi',
          'groupID': '',
          'category': 'Food',
          'location': 'Implausible Avenue',
          'description': 'Cold rice',
          'email': '',
          'website': 'https://www.sushisquad.com',
          'phone': '',
          'latLng': '52.200063,0.139313',
          'startTime': '12:00',
          'endTime': '16:30',
        },
        {
          'id': '2',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'category': 'Food',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'startTime': '10:30',
          'endTime': '16:30',
        },
        {
          'id': '3',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'emoji': '🍔',
          'title': 'Bite Club',
          'subtitle': 'Burgers',
          'groupID': '',
          'category': 'Food',
          'location': 'Donkey Common',
          'description': 'Dead cattle',
          'email': '',
          'website': 'https://www.biteclub.com',
          'phone': '01223 333333',
          'latLng': '52.202313,0.131562',
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
            body: FilteredListingsPage(filterCategory: 'Food', listings: sampleListings),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially all three listings should be visible
      expect(find.text('🍣 Sushi Squad'), findsOneWidget);
      expect(find.text('🍩 Glazed and Confused'), findsOneWidget);
      expect(find.text('🍔 Bite Club'), findsOneWidget);

      // Tap the search FAB to enter search mode
      final searchFab = find.byKey(const ValueKey('searchFab'));
      expect(searchFab, findsOneWidget);
      await tester.tap(searchFab);
      await tester.pumpAndSettle();

      // The SearchBar has a ValueKey('searchBar') on the ConstrainedBox; find the descendant TextField
      final searchBarBox = find.byKey(const ValueKey('searchBar'));
      expect(searchBarBox, findsOneWidget);

      final textFieldFinder = find.descendant(of: searchBarBox, matching: find.byType(TextField));
      expect(textFieldFinder, findsOneWidget);

      // Enter text that matches only Sushi Squad
      await tester.enterText(textFieldFinder, 'sushi');
      await tester.pumpAndSettle();

      // Only Sushi Squad should remain
      expect(find.text('🍣 Sushi Squad'), findsOneWidget);
      expect(find.text('🍩 Glazed and Confused'), findsNothing);
      expect(find.text('🍔 Bite Club'), findsNothing);

      // Clear the search using the close button in the SearchBar (Icon(Icons.close))
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // All results should be back
      expect(find.text('🍣 Sushi Squad'), findsOneWidget);
      expect(find.text('🍩 Glazed and Confused'), findsOneWidget);
      expect(find.text('🍔 Bite Club'), findsOneWidget);
    });
  });
}
