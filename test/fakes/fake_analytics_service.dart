import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/dependencies/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';

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
  Future<void> logNoticeShown(String noticeName) async {
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
