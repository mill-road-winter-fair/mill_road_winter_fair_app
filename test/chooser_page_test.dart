import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/chooser_page.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

void main() {
  setUp(() {
    onTest = true;
    staticChooserPage.value = false;
  });

  Future<void> buildChooser(WidgetTester tester,
      {List<String>? calls, ThemeData? theme, double textScale = 1}) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? appThemes['light'],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ChooserPage(
        theEvents: const [],
        onOpenTimetable: (favourites, music) =>
            calls?.add('music:$favourites:$music'),
        onOpenListings: (scope, category) => calls?.add('$scope:$category'),
        onOpenMap: (id) => calls?.add('map:$id'),
        onTabSelected: (tab) => calls?.add('tab:$tab'),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> move(WidgetTester tester, String direction) async {
    final button = find.byTooltip('$direction category');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('shows logo, carousel and existing navigation', (tester) async {
    final calls = <String>[];
    await buildChooser(tester, calls: calls);
    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('1 / 8'), findsOneWidget);
    await tester.tap(find.text('Timetable'));
    expect(calls, ['tab:2']);
  });

  testWidgets('all eight cards keep their destinations over repeated cycles',
      (tester) async {
    final calls = <String>[];
    await buildChooser(tester, calls: calls);
    const assets = [
      'foodDrink',
      'music',
      'childrens',
      'shopping',
      'charityCommunityInfo',
      'visitExperience',
      'services',
      'nearby'
    ];
    const destinations = [
      'all:food',
      'music:false:true',
      'all:performanceChildrens',
      'all:shopping',
      'all:charityCommunityInfo',
      'all:visitExperience',
      'all:service',
      'map:10'
    ];
    for (var cycle = 0; cycle < 3; cycle++) {
      for (var index = 0; index < assets.length; index++) {
        expect(find.text('${index + 1} / 8'), findsOneWidget);
        final card = find.byKey(ValueKey('choice-${assets[index]}'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        expect(calls.last, destinations[index]);
        await move(tester, 'Next');
      }
    }
    expect(find.text('1 / 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipes wrap backwards and forwards', (tester) async {
    await buildChooser(tester);
    final carousel = find.byType(PageView);
    await tester.drag(carousel, const Offset(550, 0));
    await tester.pumpAndSettle();
    expect(find.text('8 / 8'), findsOneWidget);
    await tester.drag(carousel, const Offset(-550, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 8'), findsOneWidget);
    for (var i = 0; i < 17; i++) {
      await move(tester, 'Previous');
    }
    expect(find.text('8 / 8'), findsOneWidget);
  });

  testWidgets('static preference allows immediate category changes',
      (tester) async {
    staticChooserPage.value = true;
    await buildChooser(tester);
    await move(tester, 'Previous');
    expect(find.text('8 / 8'), findsOneWidget);
    await move(tester, 'Next');
    expect(find.text('1 / 8'), findsOneWidget);
    staticChooserPage.value = false;
  });

  testWidgets(
      'resizes the carousel and preserves selection across device sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await buildChooser(tester);
    final phoneHeight = tester.getSize(find.byType(PageView)).height;
    expect(find.byTooltip('Next category').hitTestable(), findsOneWidget);
    await move(tester, 'Next');

    tester.view.physicalSize = const Size(1024, 1366);
    await tester.pumpAndSettle();
    expect(
        tester.getSize(find.byType(PageView)).height, greaterThan(phoneHeight));
    expect(tester.getSize(find.byType(PageView)).width, lessThanOrEqualTo(680));
    expect(find.text('2 / 8'), findsOneWidget);
    expect(find.byTooltip('Next category').hitTestable(), findsOneWidget);

    for (final size in [const Size(320, 568), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      if (size.width > size.height) {
        expect(tester.getSize(find.byType(PageView)).height,
            lessThan(phoneHeight));
      }
      expect(tester.takeException(), isNull);
      await move(tester, 'Next');
    }
    expect(find.text('4 / 8'), findsOneWidget);
  });

  testWidgets(
      'small phones show complete captions and controls without scrolling',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    for (final size in [
      const Size(320, 480),
      const Size(320, 568),
      const Size(360, 640),
      const Size(375, 667)
    ]) {
      tester.view.physicalSize = size;
      await buildChooser(tester);
      for (var i = 0; i < 8; i++) {
        final outerScroll = tester.state<ScrollableState>(find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first);
        expect(outerScroll.position.maxScrollExtent, 0,
            reason: 'The whole chooser should fit at $size, category $i');
        final next = find.byTooltip('Next category');
        expect(next.hitTestable(), findsOneWidget);
        final card = find.byType(Card).evaluate().where((element) {
          final rect = tester.getRect(find.byWidget(element.widget));
          return rect.contains(tester.getCenter(find.byType(PageView)));
        }).single;
        for (final text in find
            .descendant(
                of: find.byWidget(card.widget), matching: find.byType(Text))
            .evaluate()) {
          final rect = tester.getRect(find.byWidget(text.widget));
          expect(rect.bottom, lessThan(tester.getRect(next).top));
          expect(rect.top,
              greaterThan(tester.getRect(find.byType(AppBar)).bottom));
        }
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('small screens, large text and dark themes remain usable',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await buildChooser(tester, theme: appThemes['dark'], textScale: 2);
    for (var i = 0; i < 8; i++) {
      await move(tester, 'Next');
      expect(tester.takeException(), isNull);
    }
    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    await move(tester, 'Previous');
    expect(find.text('8 / 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
