import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/listings.dart';

void main() async {
  // We're on test
  onTest = true;

  // Ensure settings and permissions are mocked
  await loadSettings();
  locationPermission = LocationPermission.always;
  locationServicesEnabled = true;

  final sampleListings = [
    {
      'displayName': 'Sushi Squad',
      'endTime': '16:30',
      'id': '1',
      'name': 'sushisquad',
      'phone': '01223 222222',
      'latLng': '52.199188,0.139437',
      'primaryType': 'Food',
      'secondaryType': 'Implausible Avenue',
      'startTime': '12:00',
      'tertiaryType': 'Sushi',
      'visibleOnMap': true,
      'website': 'https://www.sushisquad.com',
    },
    {
      'displayName': 'Glazed and Confused',
      'endTime': '16:30',
      'id': '2',
      'name': 'glazedandconfused',
      'phone': '01223 111111',
      'latLng': '52.199687,0.138813',
      'primaryType': 'Food',
      'secondaryType': 'Food',
      'startTime': '10:30',
      'tertiaryType': 'Doughnuts',
      'visibleOnMap': true,
      'website': 'https://www.glazedandconfused.com',
    },
    {
      'displayName': 'Bite Club',
      'endTime': '16:30',
      'id': '3',
      'name': 'biteclub',
      'phone': '01223 333333',
      'latLng': '52.202313,0.131562',
      'primaryType': 'Food',
      'secondaryType': 'Food',
      'startTime': '14:00',
      'tertiaryType': 'Burgers',
      'visibleOnMap': true,
      'website': 'https://www.biteclub.com',
    },
  ];

  // Set global listings so pages relying on the global don't show error/loading UI
  listings = sampleListings;

  testWidgets('FilteredListingsPage search filters results based on query (UI)', (WidgetTester tester) async {
    // Start with a known current location so distance sorting works if required
    currentLatLng = const LatLng(52.199174, 0.140929);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilteredListingsPage(filterPrimaryType: 'Food', listings: sampleListings),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially all three listings should be visible
    expect(find.text('Sushi Squad'), findsOneWidget);
    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Bite Club'), findsOneWidget);

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
    expect(find.text('Sushi Squad'), findsOneWidget);
    expect(find.text('Glazed and Confused'), findsNothing);
    expect(find.text('Bite Club'), findsNothing);

    // Clear the search using the close button in the SearchBar (Icon(Icons.close))
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // All results should be back
    expect(find.text('Sushi Squad'), findsOneWidget);
    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Bite Club'), findsOneWidget);
  });
}
