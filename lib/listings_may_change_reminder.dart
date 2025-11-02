import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListingUpdateNotifier {
  static const _lastShownKey = 'listing_notice_last_shown';
  // original repeat interval was 3 days
  static const _showIntervalDays = 1;
  static final DateTime _cutoffDate = DateTime(2025, 12, 6);

  // I wouldn't usually keep commented out code but this function is handy for testing this toast notification
  // Simply uncomment it and add "ListingUpdateNotifier.resetNoticeTimer();" to the initState in map_page.dart
  // static Future<void> resetNoticeTimer() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove(_lastShownKey);
  //   debugPrint('Listing update notice timer reset.');
  // }

  static Future<void> maybeShowNotice(BuildContext context) async {
    debugPrint('maybeShowNotice called');
    // Capture the theme colours and initialise Toast before async gaps
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onPrimary;
    final fToast = FToast();
    fToast.init(context);

    // Safely perform async work
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    if (now.isAfter(_cutoffDate)) {
      debugPrint('Current date is after cutoff, not showing notice');
      return;
    }

    final lastShownMillis = prefs.getInt(_lastShownKey);
    if (lastShownMillis != null) {
      final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMillis);
      if (now.difference(lastShown).inDays < _showIntervalDays) {
        debugPrint('Notice shown recently, not showing again');
        return;
      }
    }
    debugPrint('Showing listings update notice');
    await prefs.setInt(_lastShownKey, now.millisecondsSinceEpoch);

    // --- Custom FToast with longer duration ---
    final toast = InkWell( 
      onTap:() => fToast.removeCustomToast(),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        margin: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Text(
  // original text - keep as we may restore closer to the Fair
  //        "Please note that event details may change as the Fair approaches, "
  //        "but this app will always show the most up-to-date information.",
            "This app currently shows many of "
            "the attractions you'll find at the "
            "2025 Fair on Saturday 6th December,"
            "and there’ll be more added in the "
            "lead-up to the Fair.\n\n"
            "Check back for the latest listings.",
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.CENTER,
      // original duration was 8s for the shorter message
      toastDuration: const Duration(seconds: 12),
    );
  }
}
