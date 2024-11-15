import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mill_road_winter_fair_app/about_us.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([http.Client])
import 'main_test.mocks.dart';

void main() async {
  // Load environment variables
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  mrwfApi = dotenv.env['MRWF_API'] ?? '';

  // Set up mocks
  late MockClient mockClient;
  setUp(() {
    mockClient = MockClient();
  });

  testWidgets('HomePage displays correct title, BottomNavigationBar and buttons', (WidgetTester tester) async {
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

  testWidgets('HomePage navigates to AboutUsPage when About Us in drawer is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('About Us'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutUsPage), findsOneWidget);
  });

  testWidgets('HomePage BottomNavigationBar updates currentIndex on tap', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Obtain the state after mounting
    final homePageState = tester.state(find.byType(HomePage)) as HomePageState;
    expect(homePageState.currentIndex, 1);

    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    expect(homePageState.currentIndex, 2);

    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();

    expect(homePageState.currentIndex, 3);

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(homePageState.currentIndex, 4);

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(homePageState.currentIndex, 5);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    expect(homePageState.currentIndex, 0);
  });

  testWidgets('HomePage navigateToMapAndGetDirections function changes to MapPage', (WidgetTester tester) async {
    // Define a test listing
    final listing = {
      "displayName": "Glazed and Confused",
      "email": "admin@glazedandconfued.com",
      "endTime": "16:30",
      "id": 1,
      "name": "glazedandconfused",
      "phone": "01223 111111",
      "plusCode": "9F4254XQ+VG",
      "primaryType": "Vendor",
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

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Obtain the state after mounting
    final homePageState = tester.state(find.byType(HomePage)) as HomePageState;
    final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;

    // Configure the map marker filter and add the marker
    mapPageState.filterSettings["Vendor_Food"] = true;
    await mapPageState.addMarker(listing, mockClient);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(homePageState.currentIndex, 1);

    // Trigger the navigation to map and fetch directions
    await homePageState.navigateToMapAndGetDirections(1, plusCode, mockClient);

    expect(homePageState.currentIndex, 0);
  });
}
