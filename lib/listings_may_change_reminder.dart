import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListingUpdateNotifier {
  static const _lastShownKey = 'listing_notice_last_shown';
  static const _standardShowInterval = Duration(days: 3);
  static const _fairDayShowInterval = Duration(hours: 8);

  static String get preferenceKey => 'listingUpdateNoticeEnabled${fairDate.year}';

  static String lastShownKeyFor(DateTime now) {
    final noticeName = DateUtils.isSameDay(fairDate, now)
        ? 'fair_day'
        : now.isAfter(fairDate)
            ? 'after_fair'
            : 'before_fair';

    return '${_lastShownKey}_${fairDate.year}_$noticeName';
  }

  static Duration showIntervalFor(DateTime now) {
    return DateUtils.isSameDay(fairDate, now) ? _fairDayShowInterval : _standardShowInterval;
  }

  static String titleFor(DateTime now) {
    if (DateUtils.isSameDay(fairDate, now)) {
      return 'It’s the day of the Fair!';
    }

    if (now.isAfter(fairDate)) {
      return 'Thank you!';
    }

    return 'Listings may change';
  }

  static String messageFor(DateTime now) {
    if (DateUtils.isSameDay(fairDate, now)) {
      debugPrint('Current date is Fair date; showing special notice');
      return 'The fun starts at 10.30, and we’re looking forward to seeing '
          'you there.\n\n'
          'This app contains all the latest listings, updated if they '
          'change, so you can easily see what’s on when and where.\n\n'
          'Have a wonderful day!';
    }

    if (now.isAfter(fairDate)) {
      return 'Thank you to everyone who came to the 2026 Fair and made it '
          'such a huge success.\n\n'
          'We‘ll be back in December 2027 and will be updating the app '
          'as the Fair approaches.\n\n'
          'Check back later in the year for the 2027 listings.';
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
    if (!context.mounted || (isListingsMayChange && (!listingUpdateNoticeEnabled || !(prefs.getBool(preferenceKey) ?? true)))) {
      return;
    }

    final lastShownKey = lastShownKeyFor(noticeDate);
    final lastShownMillis = prefs.getInt(lastShownKey);
    if (lastShownMillis != null) {
      final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMillis);
      if (noticeDate.difference(lastShown) < showIntervalFor(noticeDate)) {
        return;
      }
    }

    await prefs.setInt(lastShownKey, noticeDate.millisecondsSinceEpoch);
    if (!context.mounted) {
      return;
    }

    bool dontShowAgain = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(titleFor(noticeDate)),
          content: Text(messageFor(noticeDate)),
          actions: [
            if (isListingsMayChange)
              CheckboxListTile(
                value: dontShowAgain,
                onChanged: (value) {
                  setState(() => dontShowAgain = value ?? false);
                },
                title: const Text("Don't show this again"),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            TextButton(
              onPressed: () async {
                if (dontShowAgain) {
                  listingUpdateNoticeEnabled = false;
                  await prefs.setBool(preferenceKey, false);
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
