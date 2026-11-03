import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

void main() {
  testWidgets('drawer keeps its final options at the bottom when content fits', (tester) async {
    onTest = true;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final height in [900.0, 1200.0]) {
      tester.view.physicalSize = Size(400, height);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => fairDrawer(context, analyticsService: FakeAnalyticsService()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final lastTile = find.ancestor(
        of: find.text('About this app'),
        matching: find.byType(ListTile),
      );
      expect(tester.getRect(lastTile).bottom, closeTo(height - 20, 0.01));
      expect(find.text('Settings').hitTestable(), findsOneWidget);
      expect(find.text('App guide').hitTestable(), findsOneWidget);
      expect(find.text('Share this app').hitTestable(), findsOneWidget);
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.maxScrollExtent,
        0,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('drawer grows around wrapped labels and scrolls on small screens', (tester) async {
    onTest = true;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => fairDrawer(context, analyticsService: FakeAnalyticsService()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('Important information');
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    final tile = find.ancestor(of: title, matching: find.byType(ListTile));
    final titleRect = tester.getRect(title);
    final tileRect = tester.getRect(tile);
    expect(titleRect.height, greaterThan(56));
    expect(titleRect.top, greaterThanOrEqualTo(tileRect.top));
    expect(titleRect.bottom, lessThanOrEqualTo(tileRect.bottom));

    await tester.scrollUntilVisible(
      find.text('About this app'),
      150,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('About this app').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
