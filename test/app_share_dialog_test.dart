import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

class RecordingAnalytics extends FakeAnalyticsService {
  final buttons = <String>[];

  @override
  Future<void> logButtonTapped(String buttonName, {String? listingId, String? listingName}) async {
    buttons.add(buttonName);
  }
}

void main() {
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late RecordingAnalytics analytics;
  late List<MethodCall> shares;
  late List<MethodCall> toasts;
  var failSharing = false;

  setUp(() {
    analytics = RecordingAnalytics();
    shares = [];
    toasts = [];
    failSharing = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, (call) async {
      shares.add(call);
      if (failSharing) throw PlatformException(code: 'unavailable');
      return '';
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(toastChannel, (call) async {
      toasts.add(call);
      return true;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(toastChannel, null);
  });

  Future<void> openDialog(WidgetTester tester, {Size size = const Size(390, 844), double textScale = 1}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => displayAppShareDialog(context, analyticsService: analytics),
          child: const Text('Open'),
        );
      },),),
    ),);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows instructions and an accessible QR code', (tester) async {
    await openDialog(tester);
    expect(find.textContaining('iOS or Android'), findsOneWidget);
    expect(find.textContaining('choice of messaging app'), findsOneWidget);
    expect(find.bySemanticsLabel('QR code to install the Mill Road Winter Fair app'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/www.millroadwinterfair.org_mrwf-app.QR.png');
    expect(tester.takeException(), isNull);
    expect(shares, isEmpty);
  });

  testWidgets('scrollbar uses the dialogue scroll position and supports dragging', (tester) async {
    await openDialog(tester, size: const Size(320, 568), textScale: 3);
    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, !Platform.isIOS);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(scrollable.position.pixels, 0);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Close dismisses without sharing and records the action once', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(analytics.buttons, ['share_app_close']);
    expect(shares, isEmpty);
  });

  for (final dismissal in ['barrier', 'back']) {
    testWidgets('$dismissal dismisses without sharing or recording a button tap', (tester) async {
      await openDialog(tester);
      if (dismissal == 'barrier') {
        await tester.tapAt(const Offset(5, 5));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(analytics.buttons, isEmpty);
      expect(shares, isEmpty);
    });
  }

  testWidgets('sharing sends the installation link once and dismisses the dialogue', (tester) async {
    await openDialog(tester, size: const Size(320, 568), textScale: 3);
    await tester.ensureVisible(find.text('Share via message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share via message'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(analytics.buttons, ['share_app_share']);
    expect(shares, hasLength(1));
    expect(shares.single.method, 'share');
    expect(shares.single.arguments['title'], 'Share the app');
    expect(shares.single.arguments['text'],
        'I’m sharing the Mill Road Winter Fair app with you. Get it here for iOS and Android https://www.millroadwinterfair.org/mrwf-app/',);
    expect(toasts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('share failure shows feedback and leaves the underlying screen usable', (tester) async {
    failSharing = true;
    await openDialog(tester);
    await tester.tap(find.text('Share via message'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(toasts, hasLength(1));
    expect(toasts.single.method, 'showToast');
    expect(toasts.single.arguments['msg'], 'Couldn’t launch share sheet. Please try again later');
    // Let the toast plugin's four-second bookkeeping timer finish.
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    for (final textScale in [1.0, 2.0, 3.0]) {
      testWidgets('share dialogue fits $size at ${textScale}x text size', (tester) async {
        await openDialog(tester, size: size, textScale: textScale);
        expect(tester.takeException(), isNull);
        expect(find.text('Share this app'), findsOneWidget);
        expect(MediaQuery.textScalerOf(tester.element(find.text('Share this app'))).scale(15), 15 * textScale);

        await tester.ensureVisible(find.text('Share via message'));
        await tester.pumpAndSettle();
        expect(find.text('Share via message').hitTestable(), findsOneWidget);
        await tester.ensureVisible(find.text('Close'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(Dialog), findsNothing);
      });
    }
  }
}
