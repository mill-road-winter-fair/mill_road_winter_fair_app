import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mockito/annotations.dart';
import 'package:mill_road_winter_fair_app/about_us.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([http.Client])
import 'main_test.mocks.dart';

void main() async {

  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  mrwfApi = dotenv.env['MRWF_API'] ?? '';

  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
  });

  testWidgets('HomePage displays correct title and BottomNavigationBar', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify that the title is shown
    expect(find.text('Mill Road Winter Fair'), findsOneWidget);

    // Verify that BottomNavigationBar has correct items
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
  });

  testWidgets('HomePage navigates to AboutUsPage when About Us in drawer is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Open drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Tap on About Us and navigate
    await tester.tap(find.text('About Us'));
    await tester.pumpAndSettle();

    // Check if AboutUsPage is displayed
    expect(find.byType(AboutUsPage), findsOneWidget);
  });

  testWidgets('HomePage BottomNavigationBar updates currentIndex on tap', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap on the "Food" tab
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Verify the currentIndex is updated (Food tab is FilteredListingsPage with filter 'Vendor', 'Food')
    final homePageState = tester.state(find.byType(HomePage)) as HomePageState;
    expect(homePageState.currentIndex, 1);
  });

  testWidgets('HomePage navigateToMapAndGetDirections changes to MapPage and calls getDirections', (WidgetTester tester) async {
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

    when(mockClient.get(Uri.parse(url))).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final homePageState = tester.state(find.byType(HomePage)) as HomePageState;

    // Trigger the navigation to map and fetch directions
    await homePageState.navigateToMapAndGetDirections(1, plusCode, mockClient);

    // Verify that the BottomNavigationBar switched to the MapPage
    expect(homePageState.currentIndex, 0);
  });
}
