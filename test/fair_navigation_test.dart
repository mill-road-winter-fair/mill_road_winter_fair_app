import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

void main() {
  setUp(() => onTest = true);

  testWidgets('navigation keeps page indices with Home in the centre',
      (tester) async {
    final selected = <int>[];
    for (var current = 0; current < 5; current++) {
      await tester.pumpWidget(MaterialApp(
          home: FairScaffold(
        appBarTitle: 'Fair',
        body: const SizedBox.expand(),
        currentTab: current,
        onTabSelected: selected.add,
        analyticsService: FakeAnalyticsService(),
      )));
      await tester.pumpAndSettle();
      final bar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bar.items.map((item) => item.label),
          ['Map', 'Timetable', 'Home', 'Listings', 'Favourites']);
      expect(bar.currentIndex, [2, 0, 1, 3, 4][current]);
    }
    for (final label in [
      'Map',
      'Timetable',
      'Home',
      'Listings',
      'Favourites'
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(selected, [1, 2, 0, 3, 4]);
  });

  testWidgets('Home overlaps halfway and its raised half is tappable',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final selected = <int>[];
    for (final size in [
      const Size(320, 568),
      const Size(844, 390),
      const Size(1024, 1366)
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
          theme: appThemes['dark'],
          home: FairScaffold(
            appBarTitle: 'Fair',
            body: const SizedBox.expand(key: ValueKey('page-body')),
            currentTab: 1,
            onTabSelected: selected.add,
            analyticsService: FakeAnalyticsService(),
          )));
      await tester.pumpAndSettle();
      final button =
          tester.getRect(find.byKey(const ValueKey('home-navigation-button')));
      final bar = tester.getRect(find.byType(BottomNavigationBar));
      expect(button.width, 64);
      expect(button.height, 64);
      expect(button.center.dx, closeTo(bar.center.dx, .01));
      expect(button.center.dy, closeTo(bar.top, .01));
      final surface = tester.widget<BottomAppBar>(
          find.byKey(const ValueKey('navigation-bar-surface')));
      expect(surface.height, 64);
      expect(surface.shape, isA<CircularNotchedRectangle>());
      expect(surface.clipBehavior, Clip.antiAlias);
      expect(tester.getRect(find.byKey(const ValueKey('page-body'))).bottom,
          closeTo(bar.top, .01));
      await tester.tapAt(Offset(button.center.dx, button.top + 8));
      await tester.pumpAndSettle();
      expect(selected.last, 0);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('detail pages do not show bottom navigation or floating Home',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: FairScaffold(
      appBarTitle: 'Details',
      body: const SizedBox(),
      allowBack: true,
      currentTab: 0,
      onTabSelected: (_) {},
      analyticsService: FakeAnalyticsService(),
    )));
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byKey(const ValueKey('home-navigation-button')), findsNothing);
  });
}
