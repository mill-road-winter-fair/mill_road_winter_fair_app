import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListingUpdateNotifier {
  static String get preferenceKey => 'listing_update_notice_enabled_${fairDate.year}';

  static String messageFor(DateTime now) {
    if (DateUtils.isSameDay(fairDate, now)) {
      debugPrint('Current date is Fair date; showing special notice');
      return "It’s the day of the Fair!\n"
          'The fun starts at 10.30, and we’re looking forward to seeing '
          'you there.\n\n'
          'This app contains all the latest listings, updated if they '
          'change, so you can easily see what’s on when and where.\n\n'
          'Have a wonderful day!';
    }

    if (now.isAfter(fairDate)) {
      return 'Thank you to everyone who came to the 2025 Fair and made it '
          'such a huge success.\n\n'
          'We‘ll be back on December 5th 2026 and will be updating the app '
          'as that date approaches.\n\n'
          'Check back later in the year for the 2026 listings.';
    }

    return 'Event details may change as the Fair approaches, but this app '
        'will always show the most up-to-date information.\n\n'
        'Check back for the latest listings.';
  }

  static bool isListingsMayChangeNotice(DateTime now) {
    return !DateUtils.isSameDay(fairDate, now) && now.isBefore(fairDate);
  }

  static Future<void> maybeShowNotice(
    BuildContext context, {
    DateTime? now,
  }) async {
    if (onTest) {
      return;
    }

    final noticeDate = now ?? DateTime.now();
    final isListingsMayChange = isListingsMayChangeNotice(noticeDate);

    // The dismissal preference applies only before the Fair. The notices on
    // the day and afterwards must always remain available.
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted ||
        (isListingsMayChange &&
            (!listingUpdateNoticeEnabled ||
                !(prefs.getBool(preferenceKey) ?? true)))) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Listings may change'),
        content: Text(messageFor(noticeDate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Okay'),
          ),
          if (isListingsMayChange)
            FilledButton(
              onPressed: () async {
                listingUpdateNoticeEnabled = false;
                await prefs.setBool(preferenceKey, false);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text("Don't show this again"),
            ),
        ],
      ),
    );
  }
}
