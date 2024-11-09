import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mockito/mockito.dart';
import 'package:mill_road_winter_fair_app/about_us.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//Mock Plus Code Converter (so that Google's API is not called during tests)
class MockGetCoordinatesFunction extends Mock {
  Future<LatLng?> call(String plusCode, String apiKey) {
    return Future.value(const LatLng(52.199687,0.138813)); // Mocked coordinates
  }
}

void main() async {

  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  mrwfApi = dotenv.env['MRWF_API'] ?? '';

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
    final mockGetCoordinatesFromPlusCode = MockGetCoordinatesFunction();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final homePageState = tester.state(find.byType(HomePage)) as HomePageState;

    // Trigger the navigation to map and fetch directions
    await homePageState.navigateToMapAndGetDirections(1, '9F4254XQ+VG', getCoordinates: mockGetCoordinatesFromPlusCode.call);

    // Verify that the BottomNavigationBar switched to the MapPage
    expect(homePageState.currentIndex, 0);
  });
}
