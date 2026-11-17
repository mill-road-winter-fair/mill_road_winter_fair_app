// App imports
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

// Third-party imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    preferredDistanceUnits = DistanceUnits.metric;
    preferredMapMarkerSize.value = MapMarkerSize.medium;
    SharedPreferences.setMockInitialValues({});
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
      expect(find.text('Map markers:'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(preferredMapMarkerSize.value.dimension, 32.0);
    });

    test('loads saved marker sizes and defaults to Medium', () async {
      onTest = false;
      addTearDown(() => onTest = true);
      for (final saved in [null, 'small', 'medium', 'large', 'unknown']) {
        SharedPreferences.setMockInitialValues({
          if (saved != null) 'preferredMapMarkerSize': saved,
        });
        await loadSettings();
        expect(preferredMapMarkerSize.value.name,
            saved == 'small' || saved == 'large' ? saved : 'medium');
      }
    });

    testWidgets('changes and persists every marker size', (tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsPage(analyticsService: FakeAnalyticsService())));
      var currentLabel = 'Medium';
      for (final size in [MapMarkerSize.small, MapMarkerSize.large, MapMarkerSize.medium]) {
        await tester.tap(find.text(currentLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text(size.label).last);
        await tester.pumpAndSettle();
        expect(preferredMapMarkerSize.value, size);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('preferredMapMarkerSize'), size.name);
        currentLabel = size.label;
      }
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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

      // Change distance units to Cambridge
      await tester.tap(find.text('Metric'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambridge'));
      await tester.pumpAndSettle();

      // Change theme to High Contrast
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High contrast'));
      await tester.pumpAndSettle();

      // Verify SharedPreferences values
      expect(preferredDistanceUnits, DistanceUnits.cambridge);
      expect(themeNotifier.value, 'highContrast');
    });
  });
}
