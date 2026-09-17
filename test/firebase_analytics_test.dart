import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  final calls = <String>[];
  final events = <Map<String, Object?>>[];
  final properties = <String, String?>{};
  bool failEvents = false;

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async => calls.add('collection:$enabled');

  @override
  Future<void> setConsent({
    bool? adStorageConsentGranted,
    bool? analyticsStorageConsentGranted,
    bool? adPersonalizationSignalsConsentGranted,
    bool? adUserDataConsentGranted,
    bool? functionalityStorageConsentGranted,
    bool? personalizationStorageConsentGranted,
    bool? securityStorageConsentGranted,
  }) async {
    calls.add('consent:$analyticsStorageConsentGranted');
    expect(adStorageConsentGranted, false);
    expect(adPersonalizationSignalsConsentGranted, false);
    expect(adUserDataConsentGranted, false);
  }

  @override
  Future<void> logEvent({required String name, Map<String, Object>? parameters, List<AnalyticsEventItem>? items, AnalyticsCallOptions? callOptions}) async {
    if (failEvents) throw StateError('SDK unavailable');
    events.add({'name': name, 'parameters': parameters});
  }

  @override
  Future<void> logScreenView({String? screenClass, String? screenName, Map<String, Object>? parameters, AnalyticsCallOptions? callOptions}) async {
    calls.add('screen:$screenName');
  }

  @override
  Future<void> setUserProperty({required String name, required String? value, AnalyticsCallOptions? callOptions}) async {
    properties[name] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RecordingFirebaseAnalytics sdk;
  late FirebaseAnalyticsService service;

  setUp(() async {
    onTest = true;
    SharedPreferences.setMockInitialValues({});
    await loadSettings();
    usageAnalyticsEnabled = null;
    sdk = RecordingFirebaseAnalytics();
    service = FirebaseAnalyticsService(firebaseAnalytics: sdk);
  });

  for (final consent in [null, false]) {
    test('all event families and properties are suppressed for consent=$consent', () async {
      usageAnalyticsEnabled = consent;
      await service.setCurrentScreen('MapPage');
      await service.logButtonTapped('home');
      await service.logButtonTapped('listing_details', listingId: 'listing-123', listingName: 'Listing');
      await service.logSearch('mulled wine', searchArea: 'listings');
      await service.logMapMarkerTapped('Listing');
      await service.logMapTypePreferenceSet('hybrid');
      await service.logMapOrientationPreferenceSet('alwaysNorth');
      await service.logMapMarkerFilterPreferenceSet('all', true);
      await service.logRoadClosurePolygonPreferenceSet(false);
      await service.logDistanceUnitPreferenceSet('imperial');
      await service.logThemePreferenceSet('dark');
      await service.logPreferenceSet('sorting_method', 'alphabetical');
      await service.logListingSaved('Listing');
      await service.logListingUnsaved('Listing');
      await service.logDirectionsToListingRequested('Listing');
      expect(service.currentScreen, 'MapPage');
      expect(sdk.calls, isEmpty);
      expect(sdk.events, isEmpty);
      expect(sdk.properties, isEmpty);
    });
  }

  test('startup leaves unanswered consent unset and disables collection', () async {
    await service.initialize();
    expect(usageAnalyticsEnabled, isNull);
    expect((await SharedPreferences.getInstance()).getBool('usageAnalyticsEnabled'), isNull);
    expect(sdk.calls, ['collection:false', 'consent:false', 'collection:false']);
    expect(sdk.events, isEmpty);
  });

  test('saved opt-in restores properties without fabricating changes or an Unknown screen', () async {
    usageAnalyticsEnabled = true;
    selectedThemeKey = 'dark';
    await service.initialize();
    expect(sdk.calls, ['collection:false', 'consent:true', 'collection:true']);
    expect(sdk.properties['theme'], 'dark');
    expect(sdk.events, isEmpty);
  });

  test('opt-in persists consent and synchronizes preferences before tracking current screen', () async {
    await service.setCurrentScreen('SettingsPage');
    await service.setAnalyticsEnabled(true);
    expect(sdk.calls, ['collection:false', 'consent:true', 'collection:true', 'screen:SettingsPage']);
    expect((await SharedPreferences.getInstance()).getBool('usageAnalyticsEnabled'), true);
    expect(sdk.properties['distance_unit'], 'metric');
    expect(sdk.properties['sorting_method'], 'nearest');
    expect(sdk.properties['usage_analytics'], 'enabled');
    await service.logButtonTapped('theme_preference_option');
    expect(sdk.events.last['parameters'], {'button_id': 'theme_preference_option', 'screen_name': 'SettingsPage'});
  });

  test('revoking consent stops all further events and properties', () async {
    usageAnalyticsEnabled = true;
    await service.setAnalyticsEnabled(false);
    await service.logButtonTapped('home');
    await service.logThemePreferenceSet('dark');
    expect(sdk.calls, ['collection:false', 'consent:false', 'collection:false']);
    expect(sdk.events, isEmpty);
    expect(sdk.properties, isEmpty);
    expect((await SharedPreferences.getInstance()).getBool('usageAnalyticsEnabled'), false);
  });

  test('listing button events identify same-named listings without leaking context into other buttons', () async {
    usageAnalyticsEnabled = true;
    await service.setCurrentScreen('ListingsPage');
    await service.logButtonTapped('visit_listing_website', listingId: 'listing-123', listingName: 'Listing');
    await service.logButtonTapped('visit_listing_website', listingId: 'listing-456', listingName: 'Listing');
    expect(sdk.events[0]['parameters'], {
      'button_id': 'visit_listing_website', 'screen_name': 'ListingsPage', 'listing_id': 'listing-123', 'listing_name': 'Listing',
    });
    expect(sdk.events[1]['parameters'], {
      'button_id': 'visit_listing_website', 'screen_name': 'ListingsPage', 'listing_id': 'listing-456', 'listing_name': 'Listing',
    });
    await service.logButtonTapped('drawer_open');
    expect(sdk.events.last['parameters'], {'button_id': 'drawer_open', 'screen_name': 'ListingsPage'});
  });

  test('search records the entered string and search area', () async {
    usageAnalyticsEnabled = true;
    await service.logSearch('  Mulled Wine  ', searchArea: 'listings');
    expect(sdk.events.single, {
      'name': 'search',
      'parameters': {'search_term': 'Mulled Wine', 'search_area': 'listings'},
    });
  });

  test('blank searches are not recorded', () async {
    usageAnalyticsEnabled = true;
    await service.logSearch('   ', searchArea: 'timetable');
    expect(sdk.events, isEmpty);
  });

  test('show/hide all updates every map filter property', () async {
    usageAnalyticsEnabled = true;
    await service.logMapMarkerFilterPreferenceSet('all', false);
    expect(sdk.properties.length, 6);
    expect(sdk.properties.values, everyElement('false'));
    await service.logMapMarkerFilterPreferenceSet('shopping', true);
    expect(sdk.properties['map_filter_shopping'], 'true');
    expect(sdk.events.last['parameters'], {'filter_type': 'map_marker', 'category': 'shopping', 'is_enabled': 1});
  });

  test('rapid consent changes finish in the order requested', () async {
    await Future.wait([service.setAnalyticsEnabled(true), service.setAnalyticsEnabled(false)]);
    expect(usageAnalyticsEnabled, false);
    expect((await SharedPreferences.getInstance()).getBool('usageAnalyticsEnabled'), false);
    expect(sdk.calls, ['collection:false', 'consent:true', 'collection:true', 'collection:false', 'consent:false', 'collection:false']);
  });

  test('analytics backend failures do not escape into UI callbacks', () async {
    usageAnalyticsEnabled = true;
    sdk.failEvents = true;
    await expectLater(service.logButtonTapped('home'), completes);
    await expectLater(service.logPreferenceSet('sorting_method', 'nearest'), completes);
  });

  testWidgets('consent dialog saves an opt-in choice', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => TextButton(
      onPressed: () => service.showAnalyticsConsentDialog(context), child: const Text('Prompt'),
    ))));
    await tester.tap(find.text('Prompt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I agree'));
    await tester.pumpAndSettle();
    expect(usageAnalyticsEnabled, true);
    expect(find.text('I agree'), findsNothing);
  });
}
