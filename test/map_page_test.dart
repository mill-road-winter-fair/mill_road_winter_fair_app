import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

void main() async {
  // Mock location services and permissions
  locationServicesEnabled = true;
  locationPermission = LocationPermission.always;

  // Mock user settings
  await loadSettings(true);

  listings = [
    {
      'name': 'glazedandconfused',
      'displayName': 'Glazed and Confused',
      'endTime': '16:30',
      'id': '1',
      'phone': '01223 111111',
      'latLng': '52.199687,0.138813',
      'primaryType': 'Food',
      'secondaryType': 'Food',
      'startTime': '10:30',
      'tertiaryType': 'Doughnuts',
      'visibleOnMap': 'TRUE',
      'website': 'https://www.glazedandconfused.com',
    }
  ];

  // Set up mocks
  late MapPageState mapPageState;
  setUp(() {
    mapPageState = MapPage(listings: listings).createState();
  });

  testWidgets('test map type button changes map type', (WidgetTester tester) async {
    // Build the MapPage widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPage(listings: listings),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;

    // Check the initial map type
    expect(mapPageState.mapType, MapType.normal);

    // Switch the map type
    await tester.tap(find.byIcon(Icons.satellite_alt));
    await tester.pumpAndSettle();
    expect(mapPageState.mapType, MapType.hybrid);

    // Switch the map type back
    await tester.tap(find.byIcon(Icons.map));
    await tester.pumpAndSettle();
    expect(mapPageState.mapType, MapType.normal);
  });

  test('getCategoryColor returns correct color for given types', () {
    final foodColor = getCategoryColor("light", "Food");
    final shoppingColor = getCategoryColor("light", "Shopping");
    final musicColor = getCategoryColor("light", "Music");
    final eventColor = getCategoryColor("light", "Event");
    final serviceColor = getCategoryColor("light", "Service");

    expect(foodColor, const Color.fromRGBO(242, 153, 0, 1.0));
    expect(shoppingColor, const Color.fromRGBO(209, 81, 85, 1.0));
    expect(musicColor, const Color.fromRGBO(190, 110, 230, 1.0));
    expect(eventColor, const Color.fromRGBO(243, 190, 66, 1.0));
    expect(serviceColor, const Color.fromRGBO(84, 145, 245, 1.0));
  });

  testWidgets('Adds marker, opens modal bottom sheet, and checks content', (WidgetTester tester) async {
    // Override user location global
    currentLatLng = const LatLng(52.199174, 0.140929);

    // Build the MapPage widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPage(listings: listings),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Obtain the state after mounting
    final mapPageState = tester.state<MapPageState>(find.byType(MapPage));
    mapPageState.addAllVisibleMarkers(true);

    // Simulate a tap on the map marker
    const markerId = MarkerId('1');
    final marker = mapPageState.markers.values.toList().firstWhere((marker) => marker.markerId == markerId);
    marker.onTap!();
    await tester.pumpAndSettle();

    // Check the text content in the bottom sheet
    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Food • Doughnuts'), findsOneWidget);
    expect(find.text('10:30 - 16:30'), findsOneWidget);
    expect(find.text('approx. 206 m'), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
  });

  // TODO: Add test for initial polyline plotting
  // TODO: Add test for polyline updates
  // TODO: Add test for camera movements
}
