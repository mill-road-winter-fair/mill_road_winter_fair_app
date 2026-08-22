import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/listings_may_change_reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListingMayChangeReminder', () {
    testWidgets('can permanently dismiss the dialog', (WidgetTester tester) async {
      // Ensure no previous prefs — mock empty
      SharedPreferences.setMockInitialValues({});
      onTest = false;
      listingUpdateNoticeEnabled = true;

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      final showNotice = ListingUpdateNotifier.maybeShowNotice(
        tester.element(find.byType(SizedBox)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Listings may change'), findsOneWidget);
      // CheckBox should be ticked by default
      await tester.tap(find.text("Ok"));
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

        for (final noticeDate in [
          fairDate,
          fairDate.add(const Duration(days: 1)),
        ]) {
          final showNotice = ListingUpdateNotifier.maybeShowNotice(
            context,
            now: noticeDate,
          );
          await tester.pumpAndSettle();

          expect(find.text('Listings may change'), findsOneWidget);
          expect(find.text("Don't show this again"), findsNothing);

          await tester.tap(find.text('Ok'));
          await tester.pumpAndSettle();
          await showNotice;
        }

        onTest = true;
      },
    );
  });
}
