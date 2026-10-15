import 'fakes/fixed_date_time_provider.dart';
import 'mocks/listings_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'pump_with_clock.dart';

void main() {
  testWidgets('listing dialogs share the injected clock and react to a replacement', (tester) async {
    final listing = mockListing('performanceGroup');
    final app = MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: GroupListingInfoSheet(
                  title: listing['title'] as String,
                  categories: [listing['subtitle'] as String],
                  startTime: listing['startTime'] as String,
                  endTime: listing['endTime'] as String,
                  approxDistance: '',
                  colorScheme: ColorScheme.light(),
                ),
              ),
            ),
            child: const Text('Open listing'),
          ),
        ),
      ),
    );

    await tester.pumpWithClock(app, dateTimeProvider: FixedDateTimeProvider(fairDate.add(const Duration(hours: 12))));
    await tester.tap(find.text('Open listing'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('10:30—16:30')).style!.decoration, TextDecoration.none);

    await tester.pumpWithClock(app, dateTimeProvider: FixedDateTimeProvider(fairDate.add(const Duration(days: 1))));
    await tester.pump();
    expect(tester.widget<Text>(find.text('10:30—16:30')).style!.decoration, TextDecoration.lineThrough);
    expect(tester.takeException(), isNull);
  });
}
