import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings_may_change_reminder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingNoticeAnalyticsService extends FakeAnalyticsService {
  final notices = <String>[];
  final buttons = <String>[];
  final preferences = <String, String>{};

  @override
  Future<void> logNoticeShown(String noticeName) async => notices.add(noticeName);

  @override
  Future<void> logButtonTapped(String buttonName, {String? listingId, String? listingName}) async {
    buttons.add(buttonName);
  }

  @override
  Future<void> logPreferenceSet(String preference, String value) async {
    preferences[preference] = value;
  }
}

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

      final analytics = RecordingNoticeAnalyticsService();
      await tester.pumpWidget(Provider<AnalyticsService>.value(value: analytics, child: const MaterialApp(home: Scaffold(body: SizedBox()))));
      final showNotice = ListingUpdateNotifier.maybeShowNotice(
        tester.element(find.byType(SizedBox)),
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
      expect(analytics.notices, ['listings_may_change_notice']);
      expect(analytics.buttons, ['listings_may_change_notice_ok']);
      expect(analytics.preferences, {'listing_update_notice': 'disabled'});
      onTest = true;
    });

    testWidgets('tracks opting to keep the listings notice', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      onTest = false;
      listingUpdateNoticeEnabled = true;
      final analytics = RecordingNoticeAnalyticsService();

      await tester.pumpWidget(Provider<AnalyticsService>.value(value: analytics, child: const MaterialApp(home: Scaffold(body: SizedBox()))));
      final showNotice = ListingUpdateNotifier.maybeShowNotice(
        tester.element(find.byType(SizedBox)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Don't show this again"));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await showNotice;

      expect(listingUpdateNoticeEnabled, isTrue);
      expect(analytics.buttons, [
        'listings_may_change_notice_dont_show_again_toggle',
        'listings_may_change_notice_ok',
      ]);
      expect(analytics.preferences, {'listing_update_notice': 'enabled'});
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

        await tester.pumpWidget(Provider<AnalyticsService>.value(value: FakeAnalyticsService(), child: const MaterialApp(home: Scaffold(body: SizedBox()))));
        final context = tester.element(find.byType(SizedBox));

        for (final (noticeDate, expectedTitle) in [
          (fairDate, 'It’s the day of the Fair!'),
          (fairDate.add(const Duration(days: 1)), 'Thank you!'),
        ]) {
          final showNotice = ListingUpdateNotifier.maybeShowNotice(
            context,
            now: noticeDate,
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

      await tester.pumpWidget(Provider<AnalyticsService>.value(value: FakeAnalyticsService(), child: const MaterialApp(home: Scaffold(body: SizedBox()))));

      await ListingUpdateNotifier.maybeShowNotice(
        tester.element(find.byType(SizedBox)),
        now: noticeDate,
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

      final analytics = RecordingNoticeAnalyticsService();
      await tester.pumpWidget(Provider<AnalyticsService>.value(value: analytics, child: const MaterialApp(home: Scaffold(body: SizedBox()))));
      final context = tester.element(find.byType(SizedBox));

      final showFairDayNotice = ListingUpdateNotifier.maybeShowNotice(
        context,
        now: fairDate,
      );
      await tester.pumpAndSettle();

      expect(find.text('It’s the day of the Fair!'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await showFairDayNotice;

      final afterFair = fairDate.add(const Duration(days: 1));
      final showAfterFairNotice = ListingUpdateNotifier.maybeShowNotice(
        context,
        now: afterFair,
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
      expect(analytics.notices, ['fair_day_notice', 'post_fair_notice']);
      expect(analytics.buttons, ['fair_day_notice_ok', 'post_fair_notice_ok']);
      expect(analytics.preferences, isEmpty);
      onTest = true;
    });
  });
}
