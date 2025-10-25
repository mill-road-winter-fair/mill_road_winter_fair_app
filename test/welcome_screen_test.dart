import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // We're on test
  onTest = true;

  // Mock location services and permissions
  locationServicesEnabled = true;
  locationPermission = LocationPermission.always;

  // Mock user settings
  await loadSettings();

  testWidgets('WelcomeScreen footer button saves settings and navigates', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Manually unmount all widgets
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

    // Check that shared prefs have been updated
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('firstExecution'), isFalse);
  });
}
