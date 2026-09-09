import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingAnalyticsService extends FakeAnalyticsService {
  final calls = <String>[];
  final buttonEvents = <Map<String, String?>>[];
  @override
  Future<void> logButtonTapped(String buttonName, {String? listingId, String? listingName}) async {
    calls.add('tap:$buttonName');
    buttonEvents.add({'button_id': buttonName, 'listing_id': listingId, 'listing_name': listingName});
  }
  @override
  Future<void> setCurrentScreen(String screenName) async => calls.add('screen:$screenName');
  @override
  Future<void> logThemePreferenceSet(String theme) async => calls.add('theme:$theme');
  @override
  Future<void> logDistanceUnitPreferenceSet(String unit) async => calls.add('unit:$unit');
  @override
  Future<void> showAnalyticsConsentDialog(BuildContext context) async => calls.add('consent_prompt');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RecordingAnalyticsService analytics;
  setUp(() async {
    onTest = true;
    SharedPreferences.setMockInitialValues({});
    await loadSettings();
    firstExecution = true; // Avoid the listing reminder's unrelated toast timer.
    listings = [{
      'id': '1', 'visibleOnMap': 'TRUE', 'cancelled': 'FALSE', 'groupParent': 'FALSE', 'brickAndMortar': 'FALSE',
      'emoji': '', 'title': 'Listing', 'subtitle': '', 'groupID': '', 'food': 'TRUE', 'shopping': 'FALSE',
      'charityCommunityInfo': 'FALSE', 'performance': 'FALSE', 'visitExperience': 'FALSE', 'service': 'FALSE',
      'location': 'Mill Road', 'description': '', 'email': '', 'website': '', 'phone': '', 'latLng': '52.199687,0.138813',
      'imageURL': '', 'startTime': '10:30', 'endTime': '16:30',
    }];
    locationServicesEnabled = true;
    locationPermission = LocationPermission.always;
    analytics = RecordingAnalyticsService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') analytics.calls.add('haptic');
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'), (call) async => true,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'), null,
    );
  });

  testWidgets('navigation logs once after haptics and before invoking the callback', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(bottomNavigationBar: fairBottomNavigationBar(
      0, (index) => analytics.calls.add('navigate:$index'), analyticsService: analytics,
    ))));
    await tester.tap(find.text('Map'));
    expect(analytics.calls, ['haptic', 'tap:navigation_map', 'navigate:1']);
  });

  for (final width in [350.0, 500.0]) {
    testWidgets('Details logs once and invokes the callback at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme: appThemes['light'], home: Scaffold(body: SpecificListingInfoSheet(
        listingId: 'listing-123',
        cancelled: false, brickAndMortar: false, emoji: '', title: 'Listing', subtitle: '', location: '',
        description: 'Details', email: 'test@example.com', website: 'https://example.com', phoneNumber: '0123456789',
        imageURL: '', startTime: '10:30', endTime: '16:30', approxDistance: '', detailsVisible: false,
        listingFavourited: false, inDialog: false, onGetDirections: () {},
        onDetailsTapped: () => analytics.calls.add('details'), analyticsService: analytics,
      ))));
      await tester.tap(find.byIcon(Icons.info));
      expect(analytics.calls, ['haptic', 'tap:listing_details', 'details']);
      expect(analytics.buttonEvents.single, {'button_id': 'listing_details', 'listing_id': 'listing-123', 'listing_name': 'Listing'});
    });
  }

  for (final inDialog in [false, true]) {
    testWidgets('all info-sheet actions include listing context (inDialog=$inDialog)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme: appThemes['light'], home: Scaffold(body: SpecificListingInfoSheet(
        listingId: 'listing-456', cancelled: false, brickAndMortar: false, emoji: '', title: 'Another listing', subtitle: '', location: '',
        description: 'Details', email: 'test@example.com', website: 'https://example.com', phoneNumber: '0123456789',
        imageURL: '', startTime: '10:30', endTime: '16:30', approxDistance: '', detailsVisible: true,
        listingFavourited: false, inDialog: inDialog, onGetDirections: () {}, onDetailsTapped: () {}, onFavouriteTapped: () {},
        analyticsService: analytics,
      ))));
      // The sheet has one IconButton: the favourite control.
      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byIcon(Icons.directions_walk));
      await tester.tap(find.byIcon(Icons.info));
      for (final icon in [Icons.public, Icons.email, Icons.phone]) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();
      }
      for (final text in ['Website: https://example.com', 'Email: test@example.com', 'Telephone: 0123456789']) {
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
      }
      expect(analytics.buttonEvents.map((event) => event['button_id']), [
        'save_listing', 'directions_to_listing', 'listing_details',
        'visit_listing_website', 'email_listing', 'phone_listing',
        'visit_listing_website', 'email_listing', 'phone_listing',
      ]);
      for (final event in analytics.buttonEvents) {
        expect(event['listing_id'], 'listing-456');
        expect(event['listing_name'], 'Another listing');
      }
    });
  }

  testWidgets('settings logs taps and the new preference value', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SettingsPage(analyticsService: analytics)));
    analytics.calls.clear();
    await tester.tap(find.text('Imperial'));
    await tester.pumpAndSettle();
    expect(analytics.calls, ['haptic', 'tap:distanceUnit_preference_option', 'unit:imperial']);
    analytics.calls.clear();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(analytics.calls, ['haptic', 'tap:theme_preference_option', 'theme:dark']);
  });

  testWidgets('only the visible tab is tracked and returning from Settings restores it', (tester) async {
    await tester.pumpWidget(MyApp(firstExecution: false, analyticsService: analytics));
    await tester.pumpAndSettle();
    expect(analytics.calls.where((call) => call.startsWith('screen:')), ['screen:ChooserPage']);
    expect(analytics.calls, contains('consent_prompt'));
    await tester.tap(find.text('Map').last);
    await tester.pumpAndSettle();
    expect(analytics.calls.last, 'screen:MapPage');
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(analytics.calls.last, 'screen:SettingsPage');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(analytics.calls.last, 'screen:MapPage');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
