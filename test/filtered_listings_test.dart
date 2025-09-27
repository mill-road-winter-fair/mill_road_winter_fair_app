import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

void main() async {
  // Mock location services and permissions
  locationServicesEnabled = true;
  locationPermission = LocationPermission.always;

  // Mock user settings
  await loadSettings(true);

  // Build widget tree
  Future<void> pumpFilteredListingsPage(
    WidgetTester tester,
    String primaryType,
    List<Map<String, dynamic>> listings,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilteredListingsPage(
            filterPrimaryType: primaryType,
            listings: listings,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

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
        'displayName': 'Glazed and Confused',
        'endTime': '16:30',
        'id': '1',
        'name': 'glazedandconfused',
        'phone': '01223 111111',
        'latLng': '52.199687,0.138813',
        'primaryType': 'Food',
        'secondaryType': 'Food',
        'startTime': '10:30',
        'tertiaryType': 'Doughnuts',
        'website': 'https://www.glazedandconfused.com',
      },
      {
        'displayName': 'Sushi Squad',
        'endTime': '16:30',
        'id': '2',
        'name': 'sushisquad',
        'phone': '01223 222222',
        'latLng': '52.200063,0.139313',
        'primaryType': 'Food',
        'secondaryType': 'Food',
        'startTime': '12:00',
        'tertiaryType': 'Sushi',
        'website': 'https://www.sushisquad.com',
      },
    ];

    await loadSettings(true);
    await pumpFilteredListingsPage(tester, 'Food', listings);

    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Food • Doughnuts'), findsOneWidget);
    expect(find.text('10:30 - 16:30'), findsOneWidget);
    expect(find.text('approx. 206 m'), findsOneWidget);
    expect(find.text('01223 111111'), findsOneWidget);
    expect(find.text('Sushi Squad'), findsOneWidget);
    expect(find.text('Food • Sushi'), findsOneWidget);
    expect(find.text('12:00 - 16:30'), findsOneWidget);
    expect(find.text('approx. 197 m'), findsOneWidget);
    expect(find.text('01223 222222'), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsExactly(2));
    expect(find.byIcon(Icons.public), findsExactly(2));

    final dividerFinder = find.byWidgetPredicate((widget) => widget is Divider && widget.color == Colors.grey[350]);
    expect(dividerFinder, findsWidgets);
  });

  testWidgets('different sorting methodologies change the order', (WidgetTester tester) async {
    await loadSettings(true);
    // Override user location global
    currentLatLng = const LatLng(52.199174, 0.140929);

    listings = [
      {
        'displayName': 'Glazed and Confused',
        'endTime': '16:30',
        'id': '1',
        'name': 'glazedandconfused',
        'phone': '01223 111111',
        'latLng': '52.200662,0.135547',
        'primaryType': 'Food',
        'secondaryType': 'Food',
        'startTime': '10:30',
        'tertiaryType': 'Doughnuts',
        'website': 'https://www.glazedandconfused.com',
      },
      {
        'displayName': 'Sushi Squad',
        'endTime': '16:30',
        'id': '2',
        'name': 'sushisquad',
        'phone': '01223 222222',
        'latLng': '52.199188,0.139437',
        'primaryType': 'Food',
        'secondaryType': 'Food',
        'startTime': '12:00',
        'tertiaryType': 'Sushi',
        'website': 'https://www.sushisquad.com',
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
        'website': 'https://www.biteclub.com',
      },
    ];

    // Mock sorting preference is distance
    preferredSortingMethod = SortingMethod.values[1];

    await pumpFilteredListingsPage(tester, 'Food', listings);

    expect(listings[0]['name'], 'sushisquad');
    expect(listings[1]['name'], 'glazedandconfused');
    expect(listings[2]['name'], 'biteclub');

    // Mock sorting preference is alphabetical
    preferredSortingMethod = SortingMethod.values[0];

    await pumpFilteredListingsPage(tester, 'Food', listings);

    expect(listings[0]['name'], 'biteclub');
    expect(listings[1]['name'], 'glazedandconfused');
    expect(listings[2]['name'], 'sushisquad');

    // Mock sorting preference is time
    preferredSortingMethod = SortingMethod.values[2];

    await pumpFilteredListingsPage(tester, 'Food', listings);

    expect(listings[0]['name'], 'glazedandconfused');
    expect(listings[1]['name'], 'sushisquad');
    expect(listings[2]['name'], 'biteclub');
  });

  testWidgets('tapping the sorting buttons changes preferred sorting method', (WidgetTester tester) async {
    // Override user location global
    currentLatLng = const LatLng(52.199174, 0.140929);
    // Define mock values
    listings = [
      {
        'displayName': 'Glazed and Confused',
        'endTime': '16:30',
        'id': '1',
        'name': 'glazedandconfused',
        'phone': '01223 111111',
        'latLng': '52.199687,0.138813',
        'primaryType': 'Food',
        'secondaryType': 'Food',
        'startTime': '10:30',
        'tertiaryType': 'Doughnuts',
        'website': 'https://www.glazedandconfused.com',
      },
    ];

    await loadSettings(true);
    await pumpFilteredListingsPage(tester, 'Food', listings);

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
        'displayName': 'Glazed and Confused',
        'endTime': '16:30',
        'id': '1',
        'name': 'glazedandconfused',
        'phone': '01223 111111',
        'latLng': '52.199687,0.138813',
        'primaryType': 'Food',
        'secondaryType': 'Food',
        'startTime': '10:30',
        'tertiaryType': 'Doughnuts',
        'website': 'https://www.glazedandconfused.com',
      },
    ];

    await loadSettings(true);
    await pumpFilteredListingsPage(tester, 'Food', listings);

    // Preferred sorting method should have been reset to 0 (alphabetical)
    expect(preferredSortingMethod, SortingMethod.values[0]);
  });

  testWidgets('use fallback sorting when location is unavailable, do not use it when location returns', (WidgetTester tester) async {
    await loadSettings(true);

    // Mock sorting preference is distance
    preferredSortingMethod = SortingMethod.values[1];

    // Location permission is granted
    locationPermission = LocationPermission.always;

    // Define mock values
    listings = [
      {
        'displayName': 'Glazed and Confused',
        'endTime': '16:30',
        'id': '1',
        'name': 'glazedandconfused',
        'phone': '01223 111111',
        'latLng': '52.199687,0.138813',
        'primaryType': 'Food',
        'secondaryType': 'Food',
        'startTime': '10:30',
        'tertiaryType': 'Doughnuts',
        'website': 'https://www.glazedandconfused.com',
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
}
