import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsPage displays correct initial state', (WidgetTester tester) async {
    await loadSettings(true);
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    // Verify the Distance Units section
    expect(find.text('Distance Units'), findsOneWidget);
    expect(find.text('Metric'), findsOneWidget);
    expect(find.text('Metres & Kilometres'), findsOneWidget);
    expect(find.text('Imperial'), findsOneWidget);
    expect(find.text('Feet & Miles'), findsOneWidget);
    expect(find.text('Cambridge'), findsOneWidget);
    expect(find.text('Punt lengths'), findsOneWidget);

    // Verify the Theme section
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('2024 Colour Scheme'), findsOneWidget);
    expect(find.text('High Contrast'), findsOneWidget);
    expect(find.text('Colour Blind Friendly'), findsOneWidget);

    // Verify the Onboarding section
    expect(find.text('Onboarding'), findsOneWidget);
    expect(find.text('Replay Welcome Screen'), findsOneWidget);

    // Verify the App Information section
    expect(find.text('App Information'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    // Verify default settings
    expect(preferredDistanceUnits, DistanceUnits.metric);
    expect(themeNotifier.value, 'light');
  });

  testWidgets('SettingsPage changes distance units to Imperial', (WidgetTester tester) async {
    await loadSettings(true);
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    // Tap on Imperial radio button
    await tester.tap(find.text('Imperial'));
    await tester.pumpAndSettle();

    // Verify the selected distance unit
    expect(preferredDistanceUnits, DistanceUnits.imperial);
  });

  testWidgets('SettingsPage changes theme to Dark', (WidgetTester tester) async {
    await loadSettings(true);
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    // Tap on the Dark theme radio button
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Verify the selected theme
    expect(themeNotifier.value, 'dark');
  });

  testWidgets('SettingsPage changes theme to Colour Blind Friendly', (WidgetTester tester) async {
    await loadSettings(true);
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    // Tap on the Colour Blind Friendly theme radio button
    await tester.tap(find.text('Colour Blind Friendly'));
    await tester.pumpAndSettle();

    // Verify the selected theme
    expect(themeNotifier.value, 'colourBlindFriendly');
  });

  testWidgets('SettingsPage persists settings after selection', (WidgetTester tester) async {
    await loadSettings(true);
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    // Change distance units to Imperial
    await tester.tap(find.text('Imperial'));
    await tester.pumpAndSettle();

    // Change theme to High Contrast
    await tester.tap(find.text('High Contrast'));
    await tester.pumpAndSettle();

    // Verify SharedPreferences values
    expect(preferredDistanceUnits, DistanceUnits.imperial);
    expect(themeNotifier.value, 'highContrast');
  });
}
