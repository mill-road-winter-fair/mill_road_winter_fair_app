import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListingUpdateNotifier {
  static String get preferenceKey =>
      'listing_update_notice_enabled_${fairDate.year}';

  static Future<void> maybeShowNotice(BuildContext context) async {
    if (onTest || !listingUpdateNoticeEnabled) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted || !(prefs.getBool(preferenceKey) ?? true)) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Listings may change'),
        content: const Text(
          'Event details may change as the Fair approaches, but this app '
          'will always show the most up-to-date information.\n\n'
          'Check back for the latest listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Okay'),
          ),
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
