import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/analytics_explanation_page.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A service class to handle analytics events, using Firebase Analytics in production and a fake implementation for testing
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? firebaseAnalytics}) : _analytics = firebaseAnalytics;

  final FirebaseAnalytics? _analytics;
  FirebaseAnalytics get analytics => _analytics ?? FirebaseAnalytics.instance;
  String currentScreen = 'Unknown';
  Future<void>? _pendingConsentUpdate;

  Future<void> _record(Future<void> Function() action) async {
    if (usageAnalyticsEnabled != true) return;
    try {
      await action();
    } catch (error) {
      // Analytics must not break navigation or settings if the SDK is unavailable.
      debugPrint('[FIREBASE] Could not record analytics: $error');
    }
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    currentScreen = screenName;
    if (usageAnalyticsEnabled != true) return;

    // This can be handy when debugging to see which screen is currently being tracked in analytics, but it can be quite verbose, so it's commented out by default
    // debugPrint('[FIREBASE] Setting currentScreen to $currentScreen');
    await _record(() => analytics.logScreenView(
      screenName: screenName,
    ));
  }

  @override
  Future<void> logButtonTapped(String buttonName, {String? listingId, String? listingName}) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging button_click: $buttonName on screen $currentScreen');
    await _record(() => analytics.logEvent(
      name: 'button_click',
      parameters: {
        'button_id': buttonName,
        'screen_name': currentScreen,
        if (listingId != null) 'listing_id': listingId,
        if (listingName != null) 'listing_name': listingName,
      },
    ));
  }

  @override
  Future<void> logSearch(String searchTerm, {required String searchArea}) async {
    final trimmedSearchTerm = searchTerm.trim();
    if (trimmedSearchTerm.isEmpty || usageAnalyticsEnabled != true) return;

    debugPrint('[FIREBASE] Logging search in $searchArea: $trimmedSearchTerm');
    await _record(() => analytics.logEvent(
      name: 'search',
      parameters: {
        'search_term': trimmedSearchTerm,
        'search_area': searchArea,
      },
    ));
  }

  @override
  Future<void> logMapMarkerTapped(String listingName) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging map_marker_tapped: $listingName');
    await _record(() => analytics.logEvent(
      name: 'map_marker_tapped',
      parameters: {
        'listing_name': listingName,
      },
    ));
  }

  @override
  Future<void> logMapTypePreferenceSet(String mapType) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    await _record(() => analytics.setUserProperty(name: 'map_type', value: mapType));
    debugPrint('[FIREBASE] Logging map_type_preference_set: $mapType');
    await _record(() => analytics.logEvent(
      name: 'map_type_preference_set',
      parameters: {
        'map_type': mapType,
      },
    ));
  }

  @override
  Future<void> logMapOrientationPreferenceSet(String mapOrientation) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    await _record(() => analytics.setUserProperty(name: 'map_orientation', value: mapOrientation));
    debugPrint('[FIREBASE] Logging map_orientation_preference_set: $mapOrientation');
    await _record(() => analytics.logEvent(
      name: 'map_orientation_preference_set',
      parameters: {
        'map_orientation': mapOrientation,
      },
    ));
  }

  @override
  Future<void> logMapMarkerFilterPreferenceSet(String category, bool visible) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    const propertyNames = {
      'food': 'map_filter_food',
      'shopping': 'map_filter_shopping',
      'charityCommunityInfo': 'map_filter_community',
      'performances': 'map_filter_performances',
      'visitsExperiences': 'map_filter_visits',
      'services': 'map_filter_services',
    };
    final properties = category == 'all' ? propertyNames.values : [if (propertyNames[category] != null) propertyNames[category]!];
    for (final property in properties) {
      await _record(() => analytics.setUserProperty(name: property, value: visible.toString()));
    }
    debugPrint('[FIREBASE] Logging filter_changed (map_marker): $category set to $visible');
    await _record(() => analytics.logEvent(
      name: 'filter_changed',
      parameters: {
        'filter_type': 'map_marker',
        'category': category,
        'is_enabled': visible ? 1 : 0,
      },
    ));
  }

  @override
  Future<void> logRoadClosurePolygonPreferenceSet(bool visible) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    await _record(() => analytics.setUserProperty(name: 'road_closure', value: visible.toString()));
    debugPrint('[FIREBASE] Logging filter_changed (road_closure): $visible');
    await _record(() => analytics.logEvent(
      name: 'filter_changed',
      parameters: {
        'filter_type': 'road_closure',
        'is_enabled': visible ? 1 : 0,
      },
    ));
  }

  @override
  Future<void> logDistanceUnitPreferenceSet(String distanceUnit) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging preference_set (distance_unit): $distanceUnit');
    await _record(() => analytics.setUserProperty(name: 'distance_unit', value: distanceUnit));
    await _record(() => analytics.logEvent(
      name: 'preference_set',
      parameters: {
        'type': 'distance_unit',
        'value': distanceUnit,
      },
    ));
  }

  @override
  Future<void> logThemePreferenceSet(String theme) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging preference_set (theme): $theme');
    await _record(() => analytics.setUserProperty(name: 'theme', value: theme));
    await _record(() => analytics.logEvent(
      name: 'preference_set',
      parameters: {
        'type': 'theme',
        'value': theme,
      },
    ));
  }

  @override
  Future<void> logListingSaved(String listingName) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging listing_saved: $listingName');
    await _record(() => analytics.logEvent(
      name: 'listing_saved',
      parameters: {
        'listing_name': listingName,
      },
    ));
  }

  @override
  Future<void> logListingUnsaved(String listingName) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging listing_unsaved: $listingName');
    await _record(() => analytics.logEvent(
      name: 'listing_unsaved',
      parameters: {
        'listing_name': listingName,
      },
    ));
  }

  @override
  Future<void> logDirectionsToListingRequested(String listingName) async {
    if (usageAnalyticsEnabled != true) {
      return;
    }

    debugPrint('[FIREBASE] Logging listing_directions_request: $listingName');
    await _record(() => analytics.logEvent(
      name: 'listing_directions_request',
      parameters: {
        'listing_name': listingName,
      },
    ));
  }

  // Apply saved consent without recording a new choice or marking an unanswered prompt as declined.
  Future<void> initialize() async {
    await _applyConsent(usageAnalyticsEnabled == true);
    await syncPreferences();
  }

  Future<void> _applyConsent(bool enabled) async {
    await analytics.setAnalyticsCollectionEnabled(false);
    await analytics.setConsent(
      analyticsStorageConsentGranted: enabled,
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
    );
    await analytics.setAnalyticsCollectionEnabled(enabled);
  }

  // Consent and collection must change together, both at startup and in the UI.
  @override
  Future<void> setAnalyticsEnabled(bool enabled) {
    // Rapid switch taps must not let an older opt-in overwrite a later opt-out.
    final update = _pendingConsentUpdate?.then((_) => _setAnalyticsEnabled(enabled)) ?? _setAnalyticsEnabled(enabled);
    _pendingConsentUpdate = update.catchError((Object _) {});
    return update;
  }

  Future<void> _setAnalyticsEnabled(bool enabled) async {
    usageAnalyticsEnabled = false;
    await _applyConsent(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usageAnalyticsEnabled', enabled);
    usageAnalyticsEnabled = enabled;
    if (enabled) {
      await logPreferenceSet('usage_analytics', 'enabled');
      await syncPreferences();
      if (currentScreen != 'Unknown') await setCurrentScreen(currentScreen);
    }
  }

  // Refresh properties after opt-in/startup without inventing preference changes.
  Future<void> syncPreferences() async {
    if (usageAnalyticsEnabled != true) return;
    final properties = {
      'allow_personalized_ads': 'NO',
      'distance_unit': preferredDistanceUnits.name,
      'theme': selectedThemeKey,
      'sorting_method': preferredSortingMethod.name,
      'map_type': preferredMapStyleType.name,
      'map_orientation': preferredMapOrientation.name,
      'road_closure': preferredRoadClosurePolygonVisible.toString(),
    };
    for (final entry in properties.entries) {
      await _record(() => analytics.setUserProperty(name: entry.key, value: entry.value));
    }
  }

  @override
  Future<void> logPreferenceSet(String preference, String value) async {
    if (usageAnalyticsEnabled != true) return;
    await _record(() => analytics.setUserProperty(name: preference, value: value));
    await _record(() => analytics.logEvent(name: 'preference_set', parameters: {
      'type': preference,
      'value': value,
    }));
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
              'This includes the pages you view, buttons you tap and preferences you set. '
              'Also logged are the words and phrases you enter in search queries, as such we ask that you do not enter personal information in those searches. '
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
                  ..onTap = () async {
                    HapticFeedback.lightImpact();
                    logButtonTapped('analytics_explanation_consent_dialog');
                    final previousScreen = currentScreen;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnalyticsExplanationPage(analyticsService: this),
                      ),
                    );
                    if (context.mounted) setCurrentScreen(previousScreen);
                  },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              logButtonTapped('analytics_consent_decline');
              await setAnalyticsEnabled(false);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('No thanks'),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              logButtonTapped('analytics_consent_accept');
              await setAnalyticsEnabled(true);
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
  Future<void> setAnalyticsEnabled(bool enabled);
  Future<void> logPreferenceSet(String preference, String value);
  Future<void> setCurrentScreen(String screenName);
  Future<void> logMapMarkerTapped(String listingName);
  Future<void> logButtonTapped(String buttonName, {String? listingId, String? listingName});
  Future<void> logSearch(String searchTerm, {required String searchArea});
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
  Future<void> setAnalyticsEnabled(bool enabled) async {
    usageAnalyticsEnabled = enabled;
  }
  @override
  Future<void> logPreferenceSet(String preference, String value) async {}

  @override
  Future<void> setCurrentScreen(String screenName) async {
    // Do nothing
  }
  @override
  Future<void> logMapMarkerTapped(String listingName) async {
    // Do nothing
  }
  @override
  Future<void> logButtonTapped(String buttonName, {String? listingId, String? listingName}) async {
    // Do nothing
  }
  @override
  Future<void> logSearch(String searchTerm, {required String searchArea}) async {
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
