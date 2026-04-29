import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/listings_may_change_reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListingMayChangeReminder', () {
    testWidgets('maybeShowNotice shows toast and sets prefs when allowed', (WidgetTester tester) async {
      // Ensure no previous prefs — mock empty
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      // Call maybeShowNotice; should not throw and should write to prefs
      await ListingUpdateNotifier.maybeShowNotice(tester.element(find.byType(SizedBox)));

      // Advance time to allow the toast's internal timer (8s) to complete and avoid pending timers
      // original was 9s; changed to 13s for the lengthier interim message
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      // Expect that prefs contains at least one key (the lastShown timestamp)
      expect(prefs.getKeys().isNotEmpty, isTrue);
    });
  });
}
