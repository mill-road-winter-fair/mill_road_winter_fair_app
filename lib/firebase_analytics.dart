import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/globals.dart';

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
    debugPrint('[FIREBASE] Logging $buttonName button tapped on screen $currentScreen');
    await analytics.logEvent(
      name: '${buttonName}_button_tapped',
      parameters: {
        'screen': currentScreen,
      },
    );
  }

  @override
  Future<void> logMapTypePreferenceSet(String mapType) async {
    debugPrint('[FIREBASE] Logging mapType preference set to $mapType');
    await analytics.logEvent(
      name: 'mapType_preference_set',
      parameters: {
        'mapType': mapType,
      },
    );
  }
}

// An abstract class to define the interface for analytics services, allowing for easy mocking in tests
abstract class AnalyticsService {
  Future<void> setCurrentScreen(String screenName);
  Future<void> logButtonTapped(String buttonName);
  Future<void> logMapTypePreferenceSet(String mapType);
}

// A fake implementation of AnalyticsService for testing purposes
class FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> setCurrentScreen(String screenName) async {
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
}
