import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([http.Client])
import 'map_page_test.mocks.dart';

void main() async {
  // Load environment variables
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  mrwfApi = dotenv.env['MRWF_API'] ?? '';

  // Set up mocks
  late MapPageState mapPageState;
  late MockClient mockClient;
  setUp(() {
    mapPageState = const MapPage().createState();
    mockClient = MockClient();
  });

  testWidgets('test map type button changes map type', (WidgetTester tester) async {
    // Build the MapPage widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapPage(),
        ),
      ),
    );

    final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;

    // Check the initial map type
    expect(mapPageState.mapType, MapType.normal);

    // Switch the map type
    await tester.tap(find.byIcon(Icons.satellite_alt));
    await tester.pumpAndSettle();
    expect(mapPageState.mapType, MapType.satellite);

    // Switch the map type back
    await tester.tap(find.byIcon(Icons.map));
    await tester.pumpAndSettle();
    expect(mapPageState.mapType, MapType.normal);
  });

  testWidgets('addMarker filters and adds marker based on filter settings', (tester) async {
    // Define a test listing
    final listing = {
      "displayName": "Glazed and Confused",
      "email": "admin@glazedandconfued.com",
      "endTime": "16:30",
      "id": 1,
      "name": "glazedandconfused",
      "phone": "01223 111111",
      "plusCode": "9F4254XQ+VG",
      "primaryType": "Food",
      "secondaryType": "Food",
      "startTime": "10:30",
      "tertiaryType": "Doughnuts",
      "website": "https://www.glazedandconfused.com"
    };

    // Define mock values
    const plusCode = '9F4254XQ+VG';
    final encodedPlusCode = Uri.encodeComponent(plusCode);
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$googleApiKey';
    const lat = 52.199687;
    const lng = 0.138813;
    final responseBody = {
      "results": [
        {
          "geometry": {
            "location": {"lat": lat, "lng": lng}
          }
        }
      ]
    };

    // Specify when to mock
    when(mockClient.get(Uri.parse(url))).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

    // Build the widget and trigger the state
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Obtain the state after mounting
    final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;

    // Configure the map marker filter and add the marker
    mapPageState.filterSettings["Vendor_Food"] = true;
    await mapPageState.addMarker(listing, mockClient);

    // Verify that the expected marker was added
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 1);
    expect(mapPageState.markers.values.toSet().any((marker) => marker.markerId == const MarkerId('1')), true);
  });

  test('getMarkerColorHue returns correct hue for given types', () {
    final hueFood = mapPageState.getMarkerColorHue("Food");
    final hueRetail = mapPageState.getMarkerColorHue("Shopping");
    final hueMusic = mapPageState.getMarkerColorHue("Music");
    final hueEvent = mapPageState.getMarkerColorHue("Event");
    final hueService = mapPageState.getMarkerColorHue("Service");

    expect(hueFood, 23.13725490196078);
    expect(hueRetail, 0.0);
    expect(hueMusic, 332.94117647058823);
    expect(hueEvent, 43.13725490196078);
    expect(hueService, 276.0);
  });

  testWidgets('Adds marker, opens modal bottom sheet, and checks content', (WidgetTester tester) async {
    // Define a test listing
    final listing = {
      "displayName": "Glazed and Confused",
      "email": "admin@glazedandconfued.com",
      "endTime": "16:30",
      "id": 1,
      "name": "glazedandconfused",
      "phone": "01223 111111",
      "plusCode": "9F4254XQ+VG",
      "primaryType": "Food",
      "secondaryType": "Food",
      "startTime": "10:30",
      "tertiaryType": "Doughnuts",
      "website": "https://www.glazedandconfused.com"
    };

    // Define mock values
    const plusCode = '9F4254XQ+VG';
    final encodedPlusCode = Uri.encodeComponent(plusCode);
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$googleApiKey';
    const lat = 52.199687;
    const lng = 0.138813;
    final responseBody = {
      "results": [
        {
          "geometry": {
            "location": {"lat": lat, "lng": lng}
          }
        }
      ]
    };

    // Specify when to mock
    when(mockClient.get(Uri.parse(url))).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

    await tester.pumpWidget(const MaterialApp(home: MapPage()));

    // Obtain the state after mounting
    final mapPageState = tester.state<MapPageState>(find.byType(MapPage));

    // Add a marker
    await mapPageState.addMarker(listing, mockClient);
    await tester.pumpAndSettle();

    // Simulate a tap on the map marker
    final markerId = MarkerId(listing['id'].toString());
    final marker = mapPageState.markers.values.toList().firstWhere((marker) => marker.markerId == markerId);
    marker.onTap!();
    await tester.pumpAndSettle();

    // Check the text content in the bottom sheet
    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Food • Doughnuts'), findsOneWidget);
    expect(find.text('10:30 - 16:30'), findsOneWidget);
    expect(find.byIcon(Icons.directions), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
  });

  testWidgets('shows filter menu and interacts with filter options', (WidgetTester tester) async {
    // Build the MapPage widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapPage(),
        ),
      ),
    );

    // Obtain the state after mounting
    mapPageState = tester.state<MapPageState>(find.byType(MapPage));

    // Define a test listing
    var listing = {
      "displayName": "Glazed and Confused",
      "email": "admin@glazedandconfued.com",
      "endTime": "16:30",
      "id": 1,
      "name": "glazedandconfused",
      "phone": "01223 111111",
      "plusCode": "9F4254XQ+VG",
      "primaryType": "Food",
      "secondaryType": "Food",
      "startTime": "10:30",
      "tertiaryType": "Doughnuts",
      "website": "https://www.glazedandconfused.com"
    };
    // Define mock values
    var plusCode = '9F4254XQ+VG';
    var encodedPlusCode = Uri.encodeComponent(plusCode);
    var url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$googleApiKey';
    var lat = 52.199687;
    var lng = 0.138813;
    var responseBody = {
      "results": [
        {
          "geometry": {
            "location": {"lat": lat, "lng": lng}
          }
        }
      ]
    };

    // Specify when to mock
    when(mockClient.get(Uri.parse(url))).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

    // Add a marker
    await mapPageState.addMarker(listing, mockClient);
    await tester.pumpAndSettle();

    listing = {
      "displayName": "The Crafty Canvas",
      "email": "contact@craftycanvas.com",
      "endTime": "16:30",
      "id": 2,
      "name": "thecraftycanvas",
      "phone": "01223 222222",
      "plusCode": "9F42642J+QQ9",
      "primaryType": "Shopping",
      "secondaryType": "Retail",
      "startTime": "10:30",
      "tertiaryType": "Crafts",
      "website": "https://www.craftycanvas.com"
    };
    // Define mock values
    plusCode = '9F42642J+QQ9';
    encodedPlusCode = Uri.encodeComponent(plusCode);
    url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$googleApiKey';
    lat = 52.199687;
    lng = 0.138813;
    responseBody = {
      "results": [
        {
          "geometry": {
            "location": {"lat": lat, "lng": lng}
          }
        }
      ]
    };

    // Specify when to mock
    when(mockClient.get(Uri.parse(url))).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

    // Add a marker
    await mapPageState.addMarker(listing, mockClient);
    await tester.pumpAndSettle();

    listing = {
      "displayName": "The Jazz Junction",
      "email": "contact@jazzjunction.com",
      "endTime": "16:30",
      "id": 3,
      "name": "thejazzjunction",
      "phone": "01223 333333",
      "plusCode": "9F42642J+VG2",
      "primaryType": "Music",
      "secondaryType": "Music",
      "startTime": "10:30",
      "tertiaryType": "Jazz",
      "website": "https://www.jazzjunction.com"
    };
    // Define mock values
    plusCode = '9F42642J+VG2';
    encodedPlusCode = Uri.encodeComponent(plusCode);
    url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$googleApiKey';
    lat = 52.199687;
    lng = 0.138813;
    responseBody = {
      "results": [
        {
          "geometry": {
            "location": {"lat": lat, "lng": lng}
          }
        }
      ]
    };

    // Specify when to mock
    when(mockClient.get(Uri.parse(url))).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

    // Add a marker
    await mapPageState.addMarker(listing, mockClient);
    await tester.pumpAndSettle();

    listing = {
      "displayName": "Santa",
      "email": "",
      "endTime": "16:30",
      "id": 4,
      "name": "santa1",
      "phone": "",
      "plusCode": "9F42643J+CXW",
      "primaryType": "Event",
      "secondaryType": "Performance",
      "startTime": "10:30",
      "tertiaryType": "Kindly Elf",
      "website": ""
    };
    // Define mock values
    plusCode = '9F42643J+CXW';
    encodedPlusCode = Uri.encodeComponent(plusCode);
    url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$googleApiKey';
    lat = 52.199687;
    lng = 0.138813;
    responseBody = {
      "results": [
        {
          "geometry": {
            "location": {"lat": lat, "lng": lng}
          }
        }
      ]
    };

    // Specify when to mock
    when(mockClient.get(Uri.parse(url))).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

    // Add a marker
    await mapPageState.addMarker(listing, mockClient);
    await tester.pumpAndSettle();

    listing = {
      "displayName": "Information Point",
      "email": "info@millroadwinterfair.org",
      "endTime": "16:30",
      "id": 5,
      "name": "informationpoint1",
      "phone": "",
      "plusCode": "9F42642P+3WV",
      "primaryType": "Service",
      "secondaryType": "Information",
      "startTime": "10:30",
      "tertiaryType": "Help Point",
      "website": ""
    };
    // Define mock values
    plusCode = '9F42642P+3WV';
    encodedPlusCode = Uri.encodeComponent(plusCode);
    url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$googleApiKey';
    lat = 52.199687;
    lng = 0.138813;
    responseBody = {
      "results": [
        {
          "geometry": {
            "location": {"lat": lat, "lng": lng}
          }
        }
      ]
    };

    // Specify when to mock
    when(mockClient.get(Uri.parse(url))).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

    // Add a marker
    await mapPageState.addMarker(listing, mockClient);
    await tester.pumpAndSettle();

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
    expect(find.text("Filter Map Pins"), findsOneWidget);

    // Verify all checkboxes are present
    expect(find.widgetWithText(CheckboxListTile, "Food"), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, "Shopping"), findsOneWidget);
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
    await tester.tap(find.widgetWithText(CheckboxListTile, "Shopping"));
    await tester.pumpAndSettle();
    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 5);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);
    await tester.tap(find.widgetWithText(CheckboxListTile, "Shopping"));
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
    expect(find.text("Filter Map Pins"), findsNothing);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, true);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, true);

    // Re-open filter menu
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();

    // Verify "Hide All" button works
    final hideAll = find.text("Hide All");
    await tester.dragUntilVisible(
      showAll,
      find.byType(SingleChildScrollView),
      const Offset(0, 50),
    );
    await tester.tap(hideAll);
    await tester.pumpAndSettle();
    expect(find.text("Filter Map Pins"), findsNothing);
    expect(mapPageState.markers[const MarkerId('1')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('2')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('3')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('4')]?.visible, false);
    expect(mapPageState.markers[const MarkerId('5')]?.visible, false);
  });

  testWidgets('clearAllMarkers clears all markers', (tester) async {
    // Build the widget and trigger the state
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Obtain the state after mounting
    final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;

    MarkerId markerId = MarkerId('1'.toString());
    Marker newMarker = Marker(markerId: markerId);
    mapPageState.markers[markerId] = newMarker;

    expect(mapPageState.markers.isNotEmpty, true);
    expect(mapPageState.markers.length, 1);

    mapPageState.clearAllMarkers();
    expect(mapPageState.markers.isEmpty, true);
  });

  // TODO: Add test for initial polyline plotting
  // TODO: Add test for polyline updates
  // TODO: Add test for camera movements
}
