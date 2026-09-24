import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

void main() {
  group('buildListingShareText', () {
    test('uses cancellation wording for a cancelled listing', () {
      final message = buildListingShareText(
        'Glazed and Confused',
        'Gwydir St Car Park',
        '10:30',
        '16:30',
        cancelled: true,
      );

      expect(
        message,
        'Glazed and Confused at Gwydir St Car Park has been cancelled and will not be appearing at $fairName.\n'
        'https://www.millroadwinterfair.org/',
      );
      expect(message, isNot(contains('I’ll be')));
    });

    test('retains attendance wording for an active listing', () {
      final message = buildListingShareText(
        'Glazed and Confused',
        'Gwydir St Car Park',
        '10:30',
        '11:30',
        cancelled: false,
        currentTime: DateTime(2026, 12, 5, 9),
      );

      expect(
        message,
        startsWith(
          'At 10:30 I’ll be at Glazed and Confused at Gwydir St Car Park',
        ),
      );
      expect(message, isNot(contains('cancelled')));
    });
  });
}
