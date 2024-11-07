import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Mocks for dependencies
class MockClient extends Mock implements http.Client {}

//Mock Plus Code Converter (so that Google's API is not called during tests)
class MockGetCoordinatesFunction extends Mock {
  Future<LatLng?> call(String plusCode, String apiKey) {
    return Future.value(const LatLng(52.199687,0.138813)); // Mocked coordinates
  }
}

@GenerateMocks([http.Client])
void main() {
  group('MapPage tests', () {
    late MapPageState mapPageState;
    late MockClient mockClient;

    setUp(() {
      mapPageState = const MapPage().createState();
      mockClient = MockClient();
    });

    testWidgets('addMarker filters and adds marker based on filter settings', (tester) async {
      final mockGetCoordinates = MockGetCoordinatesFunction();

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
      await mapPageState.addMarker(listing, getCoordinates: mockGetCoordinates.call);

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
