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

  testWidgets('addMarker filters and adds marker based on filter settings', (tester) async {
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
    final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;
    mapPageState.addAllVisibleMarkers(true);

    // Configure the map marker filter
    mapPageState.filterSettings["Food"] = true;

    // Verify that the expected marker was added
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 2);
    expect(mapPageState.markers.values.toSet().any((marker) => marker.markerId == const MarkerId('1')), true);
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
    // Group marker content
    expect(find.text('Food Group'), findsOneWidget);
    expect(find.text('10:30 - 16:30'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('approx. 199 m'), findsOneWidget);
    // Specific marker content
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

  testWidgets('shows filter menu and interacts with filter options', (WidgetTester tester) async {
    listings = [
      {
        "displayName": "Glazed and Confused",
        "email": "admin@glazedandconfued.com",
        "endTime": "16:30",
        "id": "1",
        "name": "glazedandconfused",
        "phone": "01223 111111",
        "latLng": "52.199687,0.138813",
        "primaryType": "Food",
        "secondaryType": "Food",
        "startTime": "10:30",
        "tertiaryType": "Doughnuts",
        "visibleOnMap": "TRUE",
        "website": "https://www.glazedandconfused.com"
      },
      {
        "displayName": "The Crafty Canvas",
        "email": "contact@craftycanvas.com",
        "endTime": "16:30",
        "id": "2",
        "name": "thecraftycanvas",
        "phone": "01223 222222",
        "latLng": "52.201913,0.131984",
        "primaryType": "Shopping",
        "secondaryType": "Retail",
        "startTime": "10:30",
        "tertiaryType": "Crafts",
        "visibleOnMap": "TRUE",
        "website": "https://www.craftycanvas.com"
      },
      {
        "displayName": "The Jazz Junction",
        "email": "contact@jazzjunction.com",
        "endTime": "16:30",
        "id": "3",
        "name": "thejazzjunction",
        "phone": "01223 333333",
        "latLng": "52.202188,0.131312",
        "primaryType": "Music",
        "secondaryType": "Music",
        "startTime": "10:30",
        "tertiaryType": "Jazz",
        "visibleOnMap": "TRUE",
        "website": "https://www.jazzjunction.com"
      },
      {
        "displayName": "Santa",
        "email": "",
        "endTime": "16:30",
        "id": "4",
        "name": "santa1",
        "phone": "",
        "latLng": "52.203563,0.132437",
        "primaryType": "Event",
        "secondaryType": "Performance",
        "startTime": "10:30",
        "tertiaryType": "Kindly Elf",
        "visibleOnMap": "TRUE",
        "website": ""
      },
      {
        "displayName": "Information Point",
        "email": "info@millroadwinterfair.org",
        "endTime": "16:30",
        "id": "5",
        "name": "informationpoint1",
        "phone": "",
        "latLng": "52.200187,0.137313",
        "primaryType": "Service",
        "secondaryType": "Information",
        "startTime": "10:30",
        "tertiaryType": "Help Point",
        "visibleOnMap": "TRUE",
        "website": ""
      }
    ];

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
    mapPageState = tester.state<MapPageState>(find.byType(MapPage));
    mapPageState.addAllVisibleMarkers(true);

    // Verify that the expected marker was added
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);

    // Open the filter menu
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();

    // Verify the "Filter Map Pins" title text is shown
    expect(find.text("Filter Map Layers"), findsOneWidget);

    // Verify all checkboxes are present
    expect(find.widgetWithText(CheckboxListTile, "Food"), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, "Stalls"), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, "Music"), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, "Events"), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, "Services"), findsOneWidget);

    // Test Food checkbox
    await tester.tap(find.widgetWithText(CheckboxListTile, "Food"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);
    await tester.tap(find.widgetWithText(CheckboxListTile, "Food"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);

    // Test Shopping checkbox
    await tester.tap(find.widgetWithText(CheckboxListTile, "Stalls"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);
    await tester.tap(find.widgetWithText(CheckboxListTile, "Stalls"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);

    // Test Music checkbox
    await tester.tap(find.widgetWithText(CheckboxListTile, "Music"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);
    await tester.tap(find.widgetWithText(CheckboxListTile, "Music"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);

    // Test Events checkbox
    await tester.tap(find.widgetWithText(CheckboxListTile, "Events"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);
    await tester.tap(find.widgetWithText(CheckboxListTile, "Events"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);

    // Test Services checkbox
    await tester.tap(find.widgetWithText(CheckboxListTile, "Services"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, false);
    await tester.tap(find.widgetWithText(CheckboxListTile, "Services"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);

    // Verify "Show All" button works
    final showAll = find.text("Show All");
    await tester.dragUntilVisible(
      showAll,
      find.byType(SingleChildScrollView),
      const Offset(0, 50),
    );
    await tester.tap(showAll);
    await tester.pumpAndSettle();
    expect(find.text("Filter Map Layers"), findsOne);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);

    // Verify "Hide All" button works
    final hideAll = find.text("Hide All");
    await tester.dragUntilVisible(
      showAll,
      find.byType(SingleChildScrollView),
      const Offset(0, 50),
    );
    await tester.tap(hideAll);
    await tester.pumpAndSettle();
    expect(find.text("Filter Map Layers"), findsOne);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, false);
  });

  testWidgets('hideAllMarkers clears all markers', (tester) async {
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
        'visibleOnMap': 'TRUE',
        'website': 'https://www.glazedandconfused.com',
      }
    ];

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
    final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;
    mapPageState.addAllVisibleMarkers(true);

    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);

    mapPageState.hideAllMarkers();
    expect(mapPageState.markers[const MarkerId('1')]?.visible, false);
  });

  // TODO: Add test for initial polyline plotting
  // TODO: Add test for polyline updates
  // TODO: Add test for camera movements
}
