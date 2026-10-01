import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

void main() {
  // We're on test
  onTest = true;

  TestWidgetsFlutterBinding.ensureInitialized();

  // Load settings once for the group
  setUpAll(() async {
    await loadSettings();
  });

  setUp(() {
    selectedThemeKey = 'light';
    themeNotifier.value = 'light';
  });

  group('SettingsPage', () {
    testWidgets('displays correct initial state', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsPage(analyticsService: FakeAnalyticsService())));

      // Verify the Distance Units section
      expect(find.text('Distances:'), findsOneWidget);
      expect(find.text('Metric'), findsOneWidget);

      // Verify the Theme section
      expect(find.text('Theme:'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);

      // Verify default settings
      expect(preferredDistanceUnits, DistanceUnits.metric);
      expect(themeNotifier.value, 'light');
    });

    testWidgets('changes theme to 2025 Light', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsPage(analyticsService: FakeAnalyticsService())));

      // Tap on dropdown to open it
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(find.text('A bright theme using white pages'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('A subdued theme using black pages'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Follow the device light/dark setting'), findsOneWidget);
      expect(find.text('2024 Light'), findsOneWidget);
      expect(find.text('For the Fair that blew away'), findsOneWidget);
      expect(find.text('2025 Light'), findsOneWidget);
      expect(find.text('For last year’s Fair'), findsOneWidget);
      expect(find.text('High contrast'), findsOneWidget);
      expect(find.text('For visual accessibility needs'), findsOneWidget);
      expect(find.text('Colour blind friendly'), findsOneWidget);
      expect(find.text('For users with colour blindness'), findsOneWidget);

      await tester.tap(find.text('2025 Light'));

      // Verify the selected theme
      expect(themeNotifier.value, '2025');
    });

    testWidgets('changes distance units to Imperial', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsPage(analyticsService: FakeAnalyticsService())));

      // Tap on dropdown to open it
      await tester.tap(find.text('Metric'));
      await tester.pumpAndSettle();

      expect(find.text('Metres and kilometres'), findsOneWidget);
      expect(find.text('Imperial'), findsOneWidget);
      expect(find.text('Feet and miles'), findsOneWidget);
      expect(find.text('Cambridge'), findsOneWidget);
      expect(find.text('Punt lengths'), findsOneWidget);

      await tester.tap(find.text('Imperial'));

      // Verify the selected distance unit
      expect(preferredDistanceUnits, DistanceUnits.imperial);
    });

    testWidgets('changes theme to Dark', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsPage(analyticsService: FakeAnalyticsService())));

      // Tap on dropdown to open it
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      // Tap on the Dark theme dropdown item
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Verify the selected theme
      expect(themeNotifier.value, 'dark');
    });

    testWidgets('changes theme to Auto', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsPage(analyticsService: FakeAnalyticsService())));

      // Tap on dropdown to open it
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      // Tap on the Dark theme dropdown item
      await tester.tap(find.text('Auto'));
      await tester.pumpAndSettle();

      expect(themeNotifier.value, 'auto');
    });

    testWidgets('changes theme to Colour Blind Friendly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsPage(analyticsService: FakeAnalyticsService())));

      // Tap on dropdown to open it
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      // Tap on the Dark theme dropdown item
      await tester.tap(find.text('Colour blind friendly'));
      await tester.pumpAndSettle();

      // Verify the selected theme
      expect(themeNotifier.value, 'colourBlindFriendly');
    });

    testWidgets('persists settings after selection', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsPage(analyticsService: FakeAnalyticsService())));

      // Change distance units to Imperial
      await tester.tap(find.text('Metric'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      // Change theme to High Contrast
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High contrast'));
      await tester.pumpAndSettle();

      // Verify SharedPreferences values
      expect(preferredDistanceUnits, DistanceUnits.imperial);
      expect(themeNotifier.value, 'highContrast');
    });
  });
}
