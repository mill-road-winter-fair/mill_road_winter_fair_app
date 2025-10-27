import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

void main() {
  // We're on test
  onTest = true;

  TestWidgetsFlutterBinding.ensureInitialized();

  // Load settings once for the group
  setUpAll(() async {
    await loadSettings();
  });

  group('SettingsPage', () {
    testWidgets('displays correct initial state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

      // Verify the Distance Units section
      expect(find.text('Distance units'), findsOneWidget);
      expect(find.text('Metric'), findsOneWidget);
      expect(find.text('Metres and kilometres'), findsOneWidget);
      expect(find.text('Imperial'), findsOneWidget);
      expect(find.text('Feet and miles'), findsOneWidget);
      expect(find.text('Cambridge'), findsOneWidget);
      expect(find.text('Punt lengths'), findsOneWidget);

      // Verify the Theme section
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('2024 colour scheme'), findsOneWidget);
      expect(find.text('High contrast'), findsOneWidget);
      expect(find.text('Colour blind friendly'), findsOneWidget);

      // Verify default settings
      expect(preferredDistanceUnits, DistanceUnits.metric);
      expect(themeNotifier.value, 'light');
    });

    testWidgets('changes distance units to Imperial', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

      // Tap on Imperial radio button
      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      // Verify the selected distance unit
      expect(preferredDistanceUnits, DistanceUnits.imperial);
    });

    testWidgets('changes theme to Dark', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

      // Tap on the Dark theme radio button
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Verify the selected theme
      expect(themeNotifier.value, 'dark');
    });

    testWidgets('changes theme to Colour Blind Friendly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

      // Tap on the Colour Blind Friendly theme radio button
      await tester.tap(find.text('Colour blind friendly'));
      await tester.pumpAndSettle();

      // Verify the selected theme
      expect(themeNotifier.value, 'colourBlindFriendly');
    });

    testWidgets('persists settings after selection', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

      // Change distance units to Imperial
      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      // Change theme to High Contrast
      await tester.tap(find.text('High contrast'));
      await tester.pumpAndSettle();

      // Verify SharedPreferences values
      expect(preferredDistanceUnits, DistanceUnits.imperial);
      expect(themeNotifier.value, 'highContrast');
    });
  });
}
