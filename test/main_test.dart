import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/string_to_latlng.dart';

@GenerateMocks([http.Client])
import 'main_test.mocks.dart';

void main() async {
  // Load environment variables
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  googleMapsAndSheetsApiKey = dotenv.env['GOOGLE_MAPS_AND_SHEETS_API_KEY'] ?? '';
  googleSheetId = dotenv.env['GOOGLE_SHEET_ID'] ?? '';
  googleSheetRange = dotenv.env['GOOGLE_SHEET_RANGE'] ?? '';

  // Mock user settings
  await loadSettings(true);

  // Set up mocks
  late MockClient mockClient;
  setUp(() {
    mockClient = MockClient();
  });

  testWidgets('HomePage displays correct title, BottomNavigationBar and buttons', (WidgetTester tester) async {
    final mockGoogleSheetsResponse = {
        "range": "Sheet1!A1:L200",
        "majorDimension": "ROWS",
        "values": [
          [
            "id",
            "name",
            "displayName",
            "primaryType",
            "secondaryType",
            "tertiaryType",
            "email",
            "website",
            "phone",
            "latLng",
            "startTime",
            "endTime"
          ],
          [
            "1",
            "glazedandconfused",
            "Glazed and Confused",
            "Food",
            "Food",
            "Doughnuts",
            "admin@glazedandconfued.com",
            "https://www.glazedandconfused.com",
            "01223 111111",
            "52.199687,0.138813",
            "10:30",
            "16:30"
          ]
        ]
      };
    when(mockClient.get(Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$googleSheetId/values/$googleSheetRange?key=$googleMapsAndSheetsApiKey'))).thenAnswer((_) async => http.Response(jsonEncode(mockGoogleSheetsResponse), 200));
    await fetchListings(mockClient);

    await tester.pumpWidget(const MyApp());

    expect(find.text('Mill Road Winter Fair'), findsOneWidget);

    expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    expect(find.byIcon(Icons.satellite_alt), findsOneWidget);

    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
  });

  testWidgets('HomePage navigates to AboutTheFairPage when About the Fair in drawer is tapped', (WidgetTester tester) async {
    final mockGoogleSheetsResponse = {
      "range": "Sheet1!A1:L200",
      "majorDimension": "ROWS",
      "values": [
        [
          "id",
          "name",
          "displayName",
          "primaryType",
          "secondaryType",
          "tertiaryType",
          "email",
          "website",
          "phone",
          "latLng",
          "startTime",
          "endTime"
        ],
        [
          "1",
          "glazedandconfused",
          "Glazed and Confused",
          "Food",
          "Food",
          "Doughnuts",
          "admin@glazedandconfued.com",
          "https://www.glazedandconfused.com",
          "01223 111111",
          "52.199687,0.138813",
          "10:30",
          "16:30"
        ]
      ]
    };
    when(mockClient.get(Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$googleSheetId/values/$googleSheetRange?key=$googleMapsAndSheetsApiKey'))).thenAnswer((_) async => http.Response(jsonEncode(mockGoogleSheetsResponse), 200));
    await fetchListings(mockClient);

    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('About the Fair'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutTheFairPage), findsOneWidget);
  });

  testWidgets('HomePage navigates to SettingsPage when Settings in drawer is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('HomePage BottomNavigationBar updates currentIndex on tap', (WidgetTester tester) async {
    final mockGoogleSheetsResponse = {
      "range": "Sheet1!A1:L200",
      "majorDimension": "ROWS",
      "values": [
        [
          "id",
          "name",
          "displayName",
          "primaryType",
          "secondaryType",
          "tertiaryType",
          "email",
          "website",
          "phone",
          "latLng",
          "startTime",
          "endTime"
        ],
        [
          "1",
          "glazedandconfused",
          "Glazed and Confused",
          "Food",
          "Food",
          "Doughnuts",
          "admin@glazedandconfued.com",
          "https://www.glazedandconfused.com",
          "01223 111111",
          "52.199687,0.138813",
          "10:30",
          "16:30"
        ]
      ]
    };
    when(mockClient.get(Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$googleSheetId/values/$googleSheetRange?key=$googleMapsAndSheetsApiKey'))).thenAnswer((_) async => http.Response(jsonEncode(mockGoogleSheetsResponse), 200));
    await fetchListings(mockClient);

    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Obtain the state after mounting
    final homePageState = tester.state(find.byType(HomePage)) as HomePageState;
    expect(homePageState.index, 1);

    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    expect(homePageState.index, 2);

    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();

    expect(homePageState.index, 3);

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(homePageState.index, 4);

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(homePageState.index, 5);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    expect(homePageState.index, 0);
  });

  testWidgets('HomePage navigateToMapAndGetDirections function changes to MapPage', (WidgetTester tester) async {
    final mockGoogleSheetsResponse = {
      "range": "Sheet1!A1:L200",
      "majorDimension": "ROWS",
      "values": [
        [
          "id",
          "name",
          "displayName",
          "primaryType",
          "secondaryType",
          "tertiaryType",
          "email",
          "website",
          "phone",
          "latLng",
          "startTime",
          "endTime"
        ],
        [
          "1",
          "glazedandconfused",
          "Glazed and Confused",
          "Food",
          "Food",
          "Doughnuts",
          "admin@glazedandconfued.com",
          "https://www.glazedandconfused.com",
          "01223 111111",
          "52.199687,0.138813",
          "10:30",
          "16:30"
        ]
      ]
    };
    when(mockClient.get(Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$googleSheetId/values/$googleSheetRange?key=$googleMapsAndSheetsApiKey'))).thenAnswer((_) async => http.Response(jsonEncode(mockGoogleSheetsResponse), 200));
    await fetchListings(mockClient);

    // Define a test listing
    final mockListing = {
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
      "website": "https://www.glazedandconfused.com"
    };

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Obtain the state after mounting
    final homePageState = tester.state(find.byType(HomePage)) as HomePageState;
    final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;

    // Configure the map marker filter and theme
    mapPageState.filterSettings["Food"] = true;

    // Add the marker
    await mapPageState.addMarker(mockListing, mockClient);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(homePageState.index, 1);

    // Convert String to LatLng
    LatLng destinationCoordinates = stringToLatLng("52.199687,0.138813");

    // Trigger the navigation to map and fetch directions
    await homePageState.navigateToMapAndGetDirections("1", destinationCoordinates, mockClient);

    expect(homePageState.index, 0);
  });
}
