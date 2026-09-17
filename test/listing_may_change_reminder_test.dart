import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings_may_change_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListingMayChangeReminder', () {
    // Set firstExecution to false to simulate normal app launch
    firstExecution = false;

    test('uses a title appropriate to the date', () {
      expect(
        ListingUpdateNotifier.titleFor(fairDate.subtract(const Duration(days: 1))),
        'Listings may change',
      );
      expect(
        ListingUpdateNotifier.titleFor(fairDate),
        'It’s the day of the Fair!',
      );
      expect(
        ListingUpdateNotifier.titleFor(fairDate.add(const Duration(days: 1))),
        'Thank you!',
      );
    });

    testWidgets('can permanently dismiss the dialog', (WidgetTester tester) async {
      // Ensure no previous prefs — mock empty
      SharedPreferences.setMockInitialValues({});
      onTest = false;
      listingUpdateNoticeEnabled = true;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      final showNotice = ListingUpdateNotifier.maybeShowNotice(
        tester.element(find.byType(SizedBox)), analyticsService: FakeAnalyticsService(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Listings may change'), findsOneWidget);
      // CheckBox should be ticked by default
      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();
      await showNotice;

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ListingUpdateNotifier.preferenceKey), isFalse);
      expect(listingUpdateNoticeEnabled, isFalse);
      onTest = true;
    });

    testWidgets(
      'shows the Fair-day and post-Fair notices even when listings notice is dismissed',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          ListingUpdateNotifier.preferenceKey: false,
        });
        onTest = false;
        listingUpdateNoticeEnabled = false;

        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
        final context = tester.element(find.byType(SizedBox));

        for (final (noticeDate, expectedTitle) in [
          (fairDate, 'It’s the day of the Fair!'),
          (fairDate.add(const Duration(days: 1)), 'Thank you!'),
        ]) {
          final showNotice = ListingUpdateNotifier.maybeShowNotice(
            context,
            now: noticeDate, analyticsService: FakeAnalyticsService(),
          );
          await tester.pumpAndSettle();

          expect(find.text(expectedTitle), findsOneWidget);
          expect(find.text('Listings may change'), findsNothing);
          expect(find.text("Don't show this again"), findsNothing);

          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          await showNotice;
        }

        onTest = true;
      },
    );

    testWidgets('does not show the same notice again within its interval', (WidgetTester tester) async {
      final noticeDate = fairDate.subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        ListingUpdateNotifier.lastShownKeyFor(noticeDate): noticeDate.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
      });
      onTest = false;
      listingUpdateNoticeEnabled = true;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      await ListingUpdateNotifier.maybeShowNotice(
        tester.element(find.byType(SizedBox)),
        now: noticeDate, analyticsService: FakeAnalyticsService(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Listings may change'), findsNothing);
      onTest = true;
    });

    testWidgets('tracks the three notices independently', (WidgetTester tester) async {
      final beforeFair = fairDate.subtract(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        ListingUpdateNotifier.lastShownKeyFor(beforeFair): beforeFair.millisecondsSinceEpoch,
      });
      onTest = false;
      listingUpdateNoticeEnabled = true;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      final context = tester.element(find.byType(SizedBox));

      final showFairDayNotice = ListingUpdateNotifier.maybeShowNotice(
        context,
        now: fairDate, analyticsService: FakeAnalyticsService(),
      );
      await tester.pumpAndSettle();

      expect(find.text('It’s the day of the Fair!'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await showFairDayNotice;

      final afterFair = fairDate.add(const Duration(days: 1));
      final showAfterFairNotice = ListingUpdateNotifier.maybeShowNotice(
        context,
        now: afterFair, analyticsService: FakeAnalyticsService(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thank you!'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await showAfterFairNotice;

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(ListingUpdateNotifier.lastShownKeyFor(beforeFair)), isNotNull);
      expect(prefs.getInt(ListingUpdateNotifier.lastShownKeyFor(fairDate)), isNotNull);
      expect(prefs.getInt(ListingUpdateNotifier.lastShownKeyFor(afterFair)), isNotNull);
      onTest = true;
    });
  });
}
