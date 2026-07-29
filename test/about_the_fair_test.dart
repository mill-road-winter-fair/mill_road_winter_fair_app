import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

void main() {
  // Indicate tests are running
  onTest = true;

  setUpAll(() async {
    // Mock location services and permissions
    locationServicesEnabled = true;
    locationPermission = LocationPermission.always;

    // Load default settings
    await loadSettings();
  });

  group('AboutTheFairPage', () {
    testWidgets('back button and back gesture return to the last selected HomePage tab', (WidgetTester tester) async {
      // Minimal listings so pages render correctly
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'imageURL': '',
          'startTime': '10:30',
          'endTime': '16:30',
        }
      ];

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Obtain the HomePage state
      final homePageState = tester.state(find.byType(HomePage)) as HomePageState;

      // 1) Select Food tab (index 1)
      await tester.tap(find.text('Listings'));
      await tester.pumpAndSettle();
      expect(homePageState.index, 2);

      // Open drawer and navigate to About the Fair
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About the Fair'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutTheFairPage), findsOneWidget);

      // Tap the AppBar back button (leading) and verify we return to the Listings tab
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(homePageState.index, 2);

      // 2) Select Stalls tab (index 2)
      await tester.tap(find.text('Listings'));
      await tester.pumpAndSettle();
      expect(homePageState.index, 2);

      // Open drawer and navigate to About the Fair again
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About the Fair'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutTheFairPage), findsOneWidget);

      // Simulate system back / back gesture and verify we return to the Stalls tab
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(homePageState.index, 2);
    });
  });
}
