import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mill_road_winter_fair_app/about_app_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

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
        home: const AboutAppPage(),
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
    await tester.pumpWidget(const MaterialApp(home: AboutAppPage()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Read CONTRIBUTING.md'), 300);
    await tester.tap(find.text('Read CONTRIBUTING.md'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t open this link. Please try again.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
