import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/globals.dart';

// A service class to handle analytics events, using Firebase Analytics in production and a fake implementation for testing
class FirebaseAnalyticsService implements AnalyticsService {

  String currentScreen = 'Unknown';
  @override
  Future<void> setCurrentScreen(String screenName) async {
    currentScreen = screenName;

    debugPrint('[FIREBASE] Setting currentScreen to $currentScreen');
    await analytics.logScreenView(
      screenName: screenName,
    );
  }

  @override
  Future<void> logMenuButtonTapped() async {
    await analytics.logEvent(
      name: 'menu_button_tapped',
      parameters: {
        'screen': currentScreen,
      },
    );
  }

  @override
  Future<void> logSnowflakeButtonTapped() async {
    await analytics.logEvent(
      name: 'menu_button_tapped',
      parameters: {
        'screen': currentScreen,
      },
    );
  }
}

// An abstract class to define the interface for analytics services, allowing for easy mocking in tests
abstract class AnalyticsService {
  Future<void> setCurrentScreen(String screenName);
  Future<void> logMenuButtonTapped();
  Future<void> logSnowflakeButtonTapped();
}

// A fake implementation of AnalyticsService for testing purposes
class FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> setCurrentScreen(String screenName) async {
    // Do nothing
  }
  @override
  Future<void> logMenuButtonTapped() async {
    // Do nothing
  }
  @override
  Future<void> logSnowflakeButtonTapped() async {
    // Do nothing
  }
}
