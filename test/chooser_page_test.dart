import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/chooser_page.dart';
import 'package:mill_road_winter_fair_app/globals.dart';

void main() {
  setUp(() {
    onTest = true;
    staticChooserPage.value = false;
  });

  tearDown(() {
    staticChooserPage.value = false;
  });

  group('ChooserPage helper functions', () {
    test('hotspotEntranceOpacityForIndex reveals in sequence and reaches full opacity', () {
      expect(hotspotEntranceOpacityForIndex(0, 0.0, totalHotspots: 8), 0.0);
      expect(hotspotEntranceOpacityForIndex(0, 0.09, totalHotspots: 8), 0.0);
      expect(hotspotEntranceOpacityForIndex(0, 0.2, totalHotspots: 8), greaterThan(0.0));
      expect(hotspotEntranceOpacityForIndex(1, 0.2, totalHotspots: 8), 0.0);
      expect(hotspotEntranceOpacityForIndex(1, 0.4, totalHotspots: 8), greaterThan(0.0));
      expect(hotspotEntranceOpacityForIndex(7, 1.0, totalHotspots: 8), 1.0);
    });

    test('hotspotEntranceOpacityForIndex handles empty totals defensively', () {
      expect(hotspotEntranceOpacityForIndex(0, 0.5, totalHotspots: 0), 1.0);
    });

    test('hotspotLabelOpacityForPhase stays within the valid opacity range', () {
      for (var index = 0; index < 5; index++) {
        for (var phase = 0.0; phase <= 1.0; phase += 0.1) {
          final opacity = hotspotLabelOpacityForPhase(index, phase, visibleCount: 3);
          expect(opacity, inInclusiveRange(0.0, 1.0));
        }
      }
    });

    test('hotspotLabelOpacityForPhase produces different values for different slots', () {
      final slot0 = hotspotLabelOpacityForPhase(0, 0.25, visibleCount: 3);
      final slot1 = hotspotLabelOpacityForPhase(1, 0.25, visibleCount: 3);
      final slot2 = hotspotLabelOpacityForPhase(2, 0.25, visibleCount: 3);

      expect(slot0, isNot(equals(slot1)));
      expect(slot1, isNot(equals(slot2)));
      expect(slot0, inInclusiveRange(0.0, 1.0));
      expect(slot1, inInclusiveRange(0.0, 1.0));
      expect(slot2, inInclusiveRange(0.0, 1.0));
    });

    test('hotspotLabelOpacityForPhase is full opacity when there is only one visible item', () {
      expect(hotspotLabelOpacityForPhase(0, 0.0, visibleCount: 1), 1.0);
      expect(hotspotLabelOpacityForPhase(3, 0.8, visibleCount: 1), 1.0);
    });
  });

  group('ChooserPage widget', () {
    testWidgets('builds the chooser scaffold with the expected app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChooserPage(
            theEvents: const [],
            onOpenTimetable: (_, __) {},
            onOpenListings: (_, __) {},
            onOpenMap: (_) {},
            onTabSelected: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Welcome'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('builds successfully in static mode without starting the idle animation', (WidgetTester tester) async {
      staticChooserPage.value = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChooserPage(
            theEvents: const [],
            onOpenTimetable: (_, __) {},
            onOpenListings: (_, __) {},
            onOpenMap: (_) {},
            onTabSelected: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Welcome'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders a loading state before hotspot assets are ready', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChooserPage(
            theEvents: const [],
            onOpenTimetable: (_, __) {},
            onOpenListings: (_, __) {},
            onOpenMap: (_) {},
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Welcome'), findsOneWidget);
    });
  });
}
