import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mill_road_winter_fair_app/about_app_page.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

class _RecordingAnalyticsService extends FakeAnalyticsService {
  final calls = <String>[];

  @override
  Future<void> setCurrentScreen(String screenName) async {
    calls.add('screen:$screenName');
  }

  @override
  Future<void> logButtonTapped(String buttonName,
      {String? listingId, String? listingName}) async {
    calls.add('tap:$buttonName');
  }
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Mill Road Winter Fair',
      packageName: 'test.mrwf',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  for (final theme in appThemes.entries) {
    testWidgets(
        '${theme.key}: narrow screen with large text can reach licences and return',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: theme.value,
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: AboutAppPage(analyticsService: FakeAnalyticsService()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Version 1.2.3 · Build 42'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('View licences'), 500);
      await tester.tap(find.text('View licences'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AboutAppPage), findsOneWidget);
      expect(find.text('View licences').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed links offer feedback rather than throwing',
      (tester) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(MaterialApp(
        home: AboutAppPage(analyticsService: FakeAnalyticsService())));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Read CONTRIBUTING.md'), 300);
    await tester.tap(find.text('Read CONTRIBUTING.md'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t open this link. Please try again.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Firebase information and policy links', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
        home: AboutAppPage(analyticsService: FakeAnalyticsService())));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Privacy and Firebase Analytics'),
      500,
    );
    expect(find.text('Privacy and Firebase Analytics'), findsOneWidget);
    expect(find.textContaining('Analytics is off unless you agree to it'),
        findsOneWidget);
    expect(find.text('Read our Privacy Policy'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Read our Terms of Use'), 300);
    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('Read our Terms of Use'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracks the page and its actions', (tester) async {
    final analytics = _RecordingAnalyticsService();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    messenger.setMockMethodCallHandler(channel, (_) async => true);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [routeObserver],
      home: AboutAppPage(analyticsService: analytics),
    ));
    await tester.pumpAndSettle();
    expect(analytics.calls, contains('screen:AboutAppPage'));

    await tester.scrollUntilVisible(find.text('Read CONTRIBUTING.md'), 300);
    await tester.tap(find.text('Read CONTRIBUTING.md'));
    await tester.pumpAndSettle();
    expect(analytics.calls, contains('tap:contributing_hyperlink'));

    await tester.scrollUntilVisible(find.text('Share your feedback'), 500);
    await tester.tap(find.text('Share your feedback'));
    await tester.pumpAndSettle();
    expect(analytics.calls, contains('tap:app_feedback_hyperlink'));

    await tester.tap(find.text('View licences'));
    await tester.pumpAndSettle();
    expect(analytics.calls, contains('tap:view_licences'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
        analytics.calls.where((call) => call == 'screen:AboutAppPage').length,
        2);
  });
}
