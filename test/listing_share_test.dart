import 'mocks/listings_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

void main() {
  group('buildListingShareText', () {
    final listing = mockListing('glazedAndConfused');
    for (final timings in [
      ('15:45', '', '\nStarts at 15:45'),
      ('', '16:30', '\nEnds at 16:30'),
      ('', '', ''),
      (' 15:45 ', '   ', '\nStarts at 15:45'),
      ('   ', ' 16:30 ', '\nEnds at 16:30'),
      ('   ', '   ', ''),
    ]) {
      test('shares incomplete timings (${timings.$1}, ${timings.$2})', () {
        for (final now in [
          fairDate.subtract(const Duration(days: 1)),
          fairDate.add(const Duration(hours: 16)),
          fairDate.add(const Duration(days: 1)),
        ]) {
          final message = buildListingShareText(
            listing['title'] as String,
            listing['location'] as String,
            timings.$1,
            timings.$2,
            cancelled: false,
            currentTime: now,
          );

          expect(
            message,
            'Glazed and Confused at Gwydir Street, $fairName on ${formatFullDate(fairDate)}${timings.$3}\n'
            'https://www.millroadwinterfair.org/',
          );
        }
      });
    }

    test('keeps cancellation wording when both times are missing', () {
      final message = buildListingShareText(
        listing['title'] as String,
        listing['location'] as String,
        '',
        '',
        cancelled: true,
      );

      expect(
        message,
        'Glazed and Confused at Gwydir Street has been cancelled and will not be appearing at $fairName.\n'
        'https://www.millroadwinterfair.org/',
      );
    });

    test('uses cancellation wording for a cancelled listing', () {
      final message = buildListingShareText(
        listing['title'] as String,
        listing['location'] as String,
        '10:30',
        '16:30',
        cancelled: true,
      );

      expect(
        message,
        'Glazed and Confused at Gwydir Street has been cancelled and will not be appearing at $fairName.\n'
        'https://www.millroadwinterfair.org/',
      );
      expect(message, isNot(contains('I’ll be')));
    });

    test('retains attendance wording for an active listing', () {
      final message = buildListingShareText(
        listing['title'] as String,
        listing['location'] as String,
        '10:30',
        '11:30',
        cancelled: false,
        currentTime: DateTime(2026, 12, 5, 9),
      );

      expect(message, startsWith('At 10:30 I’ll be at Glazed and Confused at Gwydir Street'));
      expect(message, isNot(contains('cancelled')));
    });
  });
}
