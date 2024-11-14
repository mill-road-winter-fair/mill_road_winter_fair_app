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
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  mrwfApi = dotenv.env['MRWF_API'] ?? '';

  group('MapPage tests', () {
    late MapPageState mapPageState;
    late MockClient mockClient;

    setUp(() {
      mapPageState = const MapPage().createState();
      mockClient = MockClient();
    });

    testWidgets('test map type button changes map type',
            (WidgetTester tester) async {
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

    testWidgets('addMarker filters and adds marker based on filter settings',
        (tester) async {
      // Define a test listing
      final listing = {
        "displayName": "Glazed and Confused",
        "email": "admin@glazedandconfued.com",
        "endTime": "15:00",
        "id": 1,
        "name": "glazedandconfused",
        "phone": "01223 111111",
        "plusCode": "9F4254XQ+VG",
        "primaryType": "Vendor",
        "secondaryType": "Food",
        "startTime": "09:00",
        "tertiaryType": "Doughnuts",
        "website": "https://www.glazedandconfused.com"
      };

      const plusCode = '9F4254XQ+VG';
      final encodedPlusCode = Uri.encodeComponent(plusCode);
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$googleApiKey';
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

      when(mockClient.get(Uri.parse(url))).thenAnswer(
          (_) async => http.Response(jsonEncode(responseBody), 200));

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

      // Set up filter and add the marker
      mapPageState.filterSettings["Vendor_Food"] = true;
      await mapPageState.addMarker(listing, mockClient);

      // Verify that the marker was added
      expect(mapPageState.markers.isNotEmpty, true);
    });

    test('getMarkerColorHue returns correct hue for given types', () {
      final hueFood = mapPageState.getMarkerColorHue("Vendor", "Food");
      final hueRetail = mapPageState.getMarkerColorHue("Vendor", "Retail");
      final hueMusic = mapPageState.getMarkerColorHue("Performer", "");
      final hueEvent = mapPageState.getMarkerColorHue("Event", "");
      final hueService = mapPageState.getMarkerColorHue("Service", "");

      expect(hueFood, 23.13725490196078);
      expect(hueRetail, 0.0);
      expect(hueMusic, 332.94117647058823);
      expect(hueEvent, 43.13725490196078);
      expect(hueService, 276.0);
    });

    testWidgets('Adds marker, opens modal bottom sheet, and checks content',
        (WidgetTester tester) async {
      // Set up initial data
      final listing = {
        'id': 1,
        'displayName': 'Test Listing',
        'plusCode': '9F4254XQ+VG',
        'primaryType': 'Vendor',
        'secondaryType': 'Food',
        'tertiaryType': 'Restaurant',
        'startTime': '10:00 AM',
        'endTime': '8:00 PM',
        'phone': '123-456-7890',
        'website': 'https://example.com',
      };

      const plusCode = '9F4254XQ+VG';
      final encodedPlusCode = Uri.encodeComponent(plusCode);
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$googleApiKey';
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

      when(mockClient.get(Uri.parse(url))).thenAnswer(
          (_) async => http.Response(jsonEncode(responseBody), 200));

      // Pump the widget tree
      await tester.pumpWidget(const MaterialApp(home: MapPage()));

      // Access the MapPageState to add a marker directly
      final mapPageState = tester.state<MapPageState>(find.byType(MapPage));

      // Add a marker
      await mapPageState.addMarker(listing, mockClient);
      await tester.pumpAndSettle(); // Wait for the marker to be added

      // Simulate a tap on the marker
      final markerId = MarkerId(listing['id'].toString());
      final marker = mapPageState.markers
          .firstWhere((marker) => marker.markerId == markerId);
      marker.onTap!(); // Trigger the marker tap programmatically

      await tester.pumpAndSettle(); // Wait for the bottom sheet to open

      // Check the text content in the bottom sheet
      expect(find.text('Test Listing'), findsOneWidget);
      expect(find.text('Food • Restaurant'), findsOneWidget);
      expect(find.text('10:00 AM - 8:00 PM'), findsOneWidget);
      expect(find.text('123-456-7890'), findsOneWidget);
    });

    testWidgets('shows filter menu and interacts with filter options',
        (WidgetTester tester) async {
      // Build the MapPage widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapPage(),
          ),
        ),
      );

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

      // Interact with checkboxes
      await tester.tap(find.widgetWithText(CheckboxListTile, "Food"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, "Shopping"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, "Music"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, "Events"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, "Services"));
      await tester.pumpAndSettle();

      // TODO: Add tests to check that the correct pins disappear/appears when the checkboxes are toggled

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

      mapPageState.markers.add(const Marker(markerId: MarkerId('1')));
      expect(mapPageState.markers.isNotEmpty, true);

      mapPageState.clearAllMarkers();
      expect(mapPageState.markers.isEmpty, true);
    });
  });
}
