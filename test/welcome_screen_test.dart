import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
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
    testWidgets('footer button saves settings and navigates', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      // Since flutter's default test screen size is for desktop i.e. 800x600, set a sensible minimum mobile screen size
      // 375x667 is the smallest size tracked at https://gs.statcounter.com/screen-resolution-stats/mobile/united-kingdom as of Nov 2025
      TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!.physicalSize = const Size(375, 667);
      TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!.devicePixelRatio = 1.0;

      // Unmount widgets in teardown; do NOT call Fluttertoast.cancel() (causes MissingPluginException in tests)
      addTearDown(() async {
        await tester.pumpWidget(Container());
        await tester.pump(); // allow disposal to complete
      });

      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

      // The footer button text should be present
      expect(find.text('Take me straight to the app!'), findsOneWidget);

      // Tap the footer button
      await tester.tap(find.text('Take me straight to the app!'));
      await tester.pumpAndSettle();

      // Let the 20s toast timer complete to avoid "Timer still pending" when test disposes widgets
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();

      // Check that shared prefs have been updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('firstExecution'), isFalse);
    });
  });
}
