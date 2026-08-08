import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/analytics_explanation_page.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A service class to handle analytics events, using Firebase Analytics in production and a fake implementation for testing
class FirebaseAnalyticsService implements AnalyticsService {
  String currentScreen = 'Unknown';

  @override
  Future<void> setCurrentScreen(String screenName) async {
    currentScreen = screenName;

    // This can be handy when debugging to see which screen is currently being tracked in analytics, but it can be quite verbose, so it's commented out by default
    // debugPrint('[FIREBASE] Setting currentScreen to $currentScreen');
    await analytics.logScreenView(
      screenName: screenName,
    );
  }

  @override
  Future<void> logButtonTapped(String buttonName) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging button_click: $buttonName on screen $currentScreen');
    await analytics.logEvent(
      name: 'button_click',
      parameters: {
        'button_id': buttonName,
        'screen_name': currentScreen,
      },
    );
  }

  @override
  Future<void> logMapMarkerTapped(String listingName) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging map_marker_tapped: $listingName');
    await analytics.logEvent(
      name: 'map_marker_tapped',
      parameters: {
        'listing_name': listingName,
      },
    );
  }

  @override
  Future<void> logMapTypePreferenceSet(String mapType) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging map_type_preference_set: $mapType');
    await analytics.logEvent(
      name: 'map_type_preference_set',
      parameters: {
        'map_type': mapType,
      },
    );
  }

  @override
  Future<void> logMapOrientationPreferenceSet(String mapOrientation) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging map_orientation_preference_set: $mapOrientation');
    await analytics.logEvent(
      name: 'map_orientation_preference_set',
      parameters: {
        'map_orientation': mapOrientation,
      },
    );
  }

  @override
  Future<void> logMapMarkerFilterPreferenceSet(String category, bool visible) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging filter_changed (map_marker): $category set to $visible');
    await analytics.logEvent(
      name: 'filter_changed',
      parameters: {
        'filter_type': 'map_marker',
        'category': category,
        'is_enabled': visible ? 1 : 0,
      },
    );
  }

  @override
  Future<void> logRoadClosurePolygonPreferenceSet(bool visible) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging filter_changed (road_closure): $visible');
    await analytics.logEvent(
      name: 'filter_changed',
      parameters: {
        'filter_type': 'road_closure',
        'is_enabled': visible ? 1 : 0,
      },
    );
  }

  @override
  Future<void> logDistanceUnitPreferenceSet(String distanceUnit) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging preference_set (distance_unit): $distanceUnit');
    await analytics.setUserProperty(name: 'distance_unit', value: distanceUnit);
    await analytics.logEvent(
      name: 'preference_set',
      parameters: {
        'type': 'distance_unit',
        'value': distanceUnit,
      },
    );
  }

  @override
  Future<void> logThemePreferenceSet(String theme) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging preference_set (theme): $theme');
    await analytics.setUserProperty(name: 'theme', value: theme);
    await analytics.logEvent(
      name: 'preference_set',
      parameters: {
        'type': 'theme',
        'value': theme,
      },
    );
  }

  @override
  Future<void> logListingSaved(String listingName) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging listing_saved: $listingName');
    await analytics.logEvent(
      name: 'listing_saved',
      parameters: {
        'listing_name': listingName,
      },
    );
  }

  @override
  Future<void> logListingUnsaved(String listingName) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging listing_unsaved: $listingName');
    await analytics.logEvent(
      name: 'listing_unsaved',
      parameters: {
        'listing_name': listingName,
      },
    );
  }

  @override
  Future<void> logDirectionsToListingRequested(String listingName) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging listing_directions_request: $listingName');
    await analytics.logEvent(
      name: 'listing_directions_request',
      parameters: {
        'listing_name': listingName,
      },
    );
  }

  @override
  Future<void> showAnalyticsConsentDialog(BuildContext context) async {
    if (usageAnalyticsEnabled != null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Share anonymous usage data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We would like to collect anonymous usage data to help us improve the app and the Fair. '
              'No personal information is collected.',
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                text: 'What does this mean?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnalyticsExplanationPage(analyticsService: this),
                      ),
                    );
                    logButtonTapped('analytics_explanation_consent_dialog');
                  },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              usageAnalyticsEnabled = false;
              await analytics.setAnalyticsCollectionEnabled(false);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('usageAnalyticsEnabled', false);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('No thanks'),
          ),
          TextButton(
            onPressed: () async {
              usageAnalyticsEnabled = true;
              await analytics.setAnalyticsCollectionEnabled(true);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('usageAnalyticsEnabled', true);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('I agree'),
          ),
        ],
      ),
    );
  }
}

// An abstract class to define the interface for analytics services, allowing for easy mocking in tests
abstract class AnalyticsService {
  Future<void> setCurrentScreen(String screenName);
  Future<void> logMapMarkerTapped(String listingName);
  Future<void> logButtonTapped(String buttonName);
  Future<void> logMapTypePreferenceSet(String mapType);
  Future<void> logMapOrientationPreferenceSet(String mapOrientation);
  Future<void> logMapMarkerFilterPreferenceSet(String category, bool visible);
  Future<void> logRoadClosurePolygonPreferenceSet(bool visible);
  Future<void> logDistanceUnitPreferenceSet(String distanceUnit);
  Future<void> logThemePreferenceSet(String theme);
  Future<void> logListingSaved(String listingName);
  Future<void> logListingUnsaved(String listingName);
  Future<void> logDirectionsToListingRequested(String listingName);
  Future<void> showAnalyticsConsentDialog(BuildContext context);
}

// A fake implementation of AnalyticsService for testing purposes
class FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> setCurrentScreen(String screenName) async {
    // Do nothing
  }
  @override
  Future<void> logMapMarkerTapped(String listingName) async {
    // Do nothing
  }
  @override
  Future<void> logButtonTapped(String buttonName) async {
    // Do nothing
  }
  @override
  Future<void> logMapTypePreferenceSet(String mapType) async {
    // Do nothing
  }
  @override
  Future<void> logMapOrientationPreferenceSet(String mapOrientation) async {
    // Do nothing
  }
  @override
  Future<void> logMapMarkerFilterPreferenceSet(String mapMarkerCategory, bool visible) async {
    // Do nothing
  }
  @override
  Future<void> logRoadClosurePolygonPreferenceSet(bool visible) async {
    // Do nothing
  }
  @override
  Future<void> logDistanceUnitPreferenceSet(String distanceUnit) async {
    // Do nothing
  }
  @override
  Future<void> logThemePreferenceSet(String theme) async {
    // Do nothing
  }
  @override
  Future<void> logListingSaved(String listingName) async {
    // Do nothing
  }
  @override
  Future<void> logListingUnsaved(String listingName) async {
    // Do nothing
  }
  @override
  Future<void> logDirectionsToListingRequested(String listingName) async {
    // Do nothing
  }
  @override
  Future<void> showAnalyticsConsentDialog(BuildContext context) async {
    // Do nothing
  }
}
