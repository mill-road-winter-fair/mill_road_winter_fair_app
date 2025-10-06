import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

void main() async {
  // Mock location services and permissions
  locationServicesEnabled = true;
  locationPermission = LocationPermission.always;

  // Mock user settings
  await loadSettings(true);

  listings = [
    {
      'name': 'foodgroup',
      'displayName': 'Food Group',
      'endTime': '16:30',
      'id': '1',
      'latLng': '52.199838,0.139016',
      'phone': '',
      'primaryType': 'Group-Food',
      'secondaryType': 'Fake Street',
      'startTime': '10:30',
      'tertiaryType': 'Food',
      'visibleOnMap': 'TRUE',
      'website': '',
    },
    {
      'name': 'glazedandconfused',
      'displayName': 'Glazed and Confused',
      'endTime': '15:00',
      'id': '2',
      'latLng': '52.199687,0.138813',
      'phone': '01223 111111',
      'primaryType': 'Food',
      'secondaryType': 'Fake Street',
      'startTime': '11:00',
      'tertiaryType': 'Doughnuts',
      'visibleOnMap': 'FALSE',
      'website': 'https://www.glazedandconfused.com',
    },
    {
      'displayName': 'Sushi Squad',
      'endTime': '16:30',
      'id': '3',
      'name': 'sushisquad',
      'latLng': '52.199188,0.139437',
      'phone': '01223 222222',
      'primaryType': 'Food',
      'secondaryType': 'Implausible Avenue',
      'startTime': '12:00',
      'tertiaryType': 'Sushi',
      'visibleOnMap': 'TRUE',
      'website': 'https://www.sushisquad.com',
    }
  ];

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

  testWidgets('Adds markers, opens modal bottom sheet for specific marker, and checks content', (WidgetTester tester) async {
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
    expect(find.text('Food Group'), findsOneWidget);
    expect(find.text('10:30 - 16:30'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('approx. 199 m'), findsOneWidget);
    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('11:00 - 15:00'), findsOneWidget);
    expect(find.text('Fake Street • Doughnuts'), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
  });

  testWidgets('Adds markers, opens modal bottom sheet for group marker, and checks content', (WidgetTester tester) async {
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
    const markerId = MarkerId('3');
    final marker = mapPageState.markers.values.toList().firstWhere((marker) => marker.markerId == markerId);
    marker.onTap!();
    await tester.pumpAndSettle();

    // Check the text content in the bottom sheet
    expect(find.text('Sushi Squad'), findsOneWidget);
    expect(find.text('12:00 - 16:30'), findsOneWidget);
    expect(find.text('Implausible Avenue • Sushi'), findsOneWidget);
    expect(find.text('approx. 135 m'), findsOneWidget);
    expect(find.text('01223 222222'), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
  });

  // TODO: Add test for initial polyline plotting
  // TODO: Add test for polyline updates
  // TODO: Add test for camera movements
}
