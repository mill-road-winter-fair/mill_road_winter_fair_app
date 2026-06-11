import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' hide RootWidget;
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // We're on test
  onTest = true;

  // Mock location services and permissions
  locationServicesEnabled = true;
  locationPermission = LocationPermission.always;

  // Mock user settings before tests run
  setUpAll(() async {
    await loadSettings();
  });

  group('WelcomeScreen', () {
    testWidgets('displays welcome screen on first app execution', (WidgetTester tester) async {
      // Set firstExecution to true to simulate first time app launch
      firstExecution = true;

      // Set a realistic window size to avoid layout overflow in the test
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      // Pump the RootWidget to test that the app correctly chooses the WelcomeScreen
      await tester.pumpWidget(const RootWidget());

      // Verify that the WelcomeScreen is displayed
      expect(find.byType(WelcomeScreen), findsOneWidget);

      // Verify that OnBoardingPage is rendered within the WelcomeScreen
      expect(find.byType(OnBoardingPage), findsOneWidget);

      // Verify the main action button is visible
      // This confirms the welcome screen UI is properly initialized
      expect(find.text('Take me straight to the app!'), findsOneWidget);
    });

    testWidgets('displays MyApp when not first app execution', (WidgetTester tester) async {
      // Set firstExecution to false to simulate subsequent app launch
      firstExecution = false;

      // Mock user settings and provide a dummy listing to avoid triggering API fetch/retries and timers
      await loadSettings();
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.200662,0.135547', // 535m
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'description': 'Nice buns',
          'visibleOnMap': true,
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      // Pump the RootWidget
      await tester.pumpWidget(const RootWidget());

      // Verify that WelcomeScreen is NOT displayed
      expect(find.byType(WelcomeScreen), findsNothing);

      // Verify that MyApp is displayed
      expect(find.byType(MyApp), findsOneWidget);

      // Handle the potential toast timer from ListingUpdateNotifier.maybeShowNotice
      // Use a long pump to ensure any 20s toast timer completes
      await tester.pump(const Duration(seconds: 21));
    });

    testWidgets('skip button saves settings and navigates', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      firstExecution = true;

      // Provide a dummy listing to avoid triggering API fetch/retries and timers
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.200662,0.135547',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'description': 'Nice buns',
          'visibleOnMap': true,
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      // Set a realistic window size to avoid layout overflow in the test
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      // Pump the RootWidget
      await tester.pumpWidget(const RootWidget());

      // Verify the 'Skip' button is present and tap it
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Verify that MyApp is now displayed
      expect(find.byType(MyApp), findsOneWidget);

      // Handle the 20s toast timer from ListingUpdateNotifier.maybeShowNotice
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();

      // Check that shared prefs have been updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('firstExecution'), isFalse);
    });

    testWidgets('next button advances onboarding slides', (WidgetTester tester) async {
      firstExecution = true;

      // Set a realistic window size to avoid layout overflow in the test
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      // Pump the RootWidget
      await tester.pumpWidget(const RootWidget());

      // Verify we are on the first page
      expect(find.text('Welcome to the official\nMill Road Winter Fair app!'), findsOneWidget);
      expect(find.text('What do the pins mean?'), findsNothing);

      // Find and tap the 'Next' button (the arrow forward icon)
      final nextButton = find.byIcon(Icons.arrow_forward);
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Verify we have advanced to the second page
      expect(find.text('What do the pins mean?'), findsOneWidget);
      expect(find.text('Welcome to the official\nMill Road Winter Fair app!'), findsNothing);
    });

    testWidgets('done button saves settings and navigates', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      firstExecution = true;

      // Provide a dummy listing to avoid triggering API fetch/retries and timers
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.200662,0.135547',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'description': 'Nice buns',
          'visibleOnMap': true,
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      // Set a realistic window size to avoid layout overflow in the test
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      // Pump the RootWidget
      await tester.pumpWidget(const RootWidget());

      // Advance through the onboarding slides to reach the last page
      final nextButton = find.byIcon(Icons.arrow_forward);
      for (int i = 0; i < 4; i++) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }

      // Verify the 'Done' button is present and tap it
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify that MyApp is now displayed
      expect(find.byType(MyApp), findsOneWidget);

      // Handle the 20s toast timer from ListingUpdateNotifier.maybeShowNotice
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();

      // Check that shared prefs have been updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('firstExecution'), isFalse);
    });

    testWidgets('Take me straight to the app button saves settings and navigates', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      // Since flutter's default test screen size is for desktop i.e. 800x600, set a sensible minimum mobile screen size
      // 375x667 is the smallest size tracked at https://gs.statcounter.com/screen-resolution-stats/mobile/united-kingdom as of Nov 2025
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Unmount widgets in teardown; do NOT call Fluttertoast.cancel() (causes MissingPluginException in tests)
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pumpWidget(Container());
        await tester.pump(); // allow disposal to complete
      });

      // Provide a dummy listing to avoid triggering API fetch/retries and timers
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.200662,0.135547',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'description': 'Nice buns',
          'visibleOnMap': true,
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      // Pump the RootWidget
      firstExecution = true;
      await tester.pumpWidget(const RootWidget());

      // The footer button text should be present
      expect(find.text('Take me straight to the app!'), findsOneWidget);

      // Tap the footer button
      await tester.tap(find.text('Take me straight to the app!'));
      await tester.pumpAndSettle();

      // Verify that MyApp is now displayed
      expect(find.byType(MyApp), findsOneWidget);

      // Let the 20s toast timer complete to avoid "Timer still pending" when test disposes widgets
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();

      // Check that shared prefs have been updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('firstExecution'), isFalse);
    });
  });
}
