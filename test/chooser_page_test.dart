import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/main_menu.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

void main() {
  setUp(() {
    onTest = true;
    staticMainMenuPage.value = false;
  });

  Future<void> buildMainMenu(WidgetTester tester,
      {List<String>? calls, ThemeData? theme, double textScale = 1}) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? appThemes['light'],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: MainMenu(
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
    final carousel = find.byType(PageView);
    await tester.ensureVisible(carousel);
    await tester.drag(
        carousel,
        Offset(
            tester.getSize(carousel).width *
                .56 *
                (direction == 'Next' ? -1 : 1),
            0));
    await tester.pumpAndSettle();
  }

  testWidgets('shows logo, carousel and existing navigation', (tester) async {
    final calls = <String>[];
    await buildMainMenu(tester, calls: calls);
    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Food & Drink'), findsOneWidget);
    await tester.tap(find.text('Timetable'));
    expect(calls, ['tab:2']);
  });

  testWidgets('snowflake meets the caption and backdrop follows the selection',
      (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await buildMainMenu(tester);
    expect(find.byTooltip('Previous category'), findsNothing);
    expect(find.byTooltip('Next category'), findsNothing);
    expect(find.text('1 / 8'), findsNothing);
    final snowflake =
        tester.getRect(find.byKey(const ValueKey('carousel-snowflake')));
    final caption =
        tester.getRect(find.byKey(const ValueKey('category-caption-box')));
    expect(snowflake.center.dy, closeTo(caption.top, .01));
    expect(snowflake.height,
        greaterThan(tester.getSize(find.byType(PageView)).height * .8));
    expect(find.byKey(const ValueKey('diffuse-foodDrink')), findsOneWidget);
    await move(tester, 'Next');
    expect(find.byKey(const ValueKey('diffuse-music')), findsOneWidget);
    expect(find.byKey(const ValueKey('diffuse-foodDrink')), findsNothing);
    expect(find.text('Music'), findsOneWidget);
  });

  testWidgets('all eight cards keep their destinations over repeated cycles',
      (tester) async {
    final calls = <String>[];
    await buildMainMenu(tester, calls: calls);
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
        final card = find.byKey(ValueKey('choice-${assets[index]}'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        expect(calls.last, destinations[index]);
        await move(tester, 'Next');
      }
    }
    expect(find.text('Food & Drink'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipes wrap backwards and forwards', (tester) async {
    await buildMainMenu(tester);
    final carousel = find.byType(PageView);
    await tester.drag(
        carousel, Offset(tester.getSize(carousel).width * .56, 0));
    await tester.pumpAndSettle();
    expect(find.text('Nearby'), findsOneWidget);
    await tester.drag(
        carousel, Offset(-tester.getSize(carousel).width * .56, 0));
    await tester.pumpAndSettle();
    expect(find.text('Food & Drink'), findsOneWidget);
    for (var i = 0; i < 17; i++) {
      await move(tester, 'Previous');
    }
    expect(find.text('Nearby'), findsOneWidget);
  });

  testWidgets('artwork descends and collapses continuously during a swipe',
      (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await buildMainMenu(tester);
    final food = find.byKey(const ValueKey('choice-foodDrink'));
    final initial = tester.getRect(food);
    final gesture = await tester.startGesture(tester.getCenter(food));
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-75, 0));
    await tester.pump();
    final during = tester.getRect(food);
    expect(during.top, greaterThan(initial.top));
    expect(during.height, lessThan(initial.height));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a neighbour selects it before opening its destination',
      (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <String>[];
    await buildMainMenu(tester, calls: calls);
    final music = find.byKey(const ValueKey('choice-music'));
    final visible =
        tester.getRect(music).intersect(tester.getRect(find.byType(PageView)));
    await tester.tapAt(visible.center);
    await tester.pumpAndSettle();
    expect(find.text('Music'), findsOneWidget);
    expect(calls, isEmpty);
    await tester.tap(find.byKey(const ValueKey('selected-category')));
    expect(calls, ['music:false:true']);
  });

  testWidgets('static preference allows immediate category changes',
      (tester) async {
    staticMainMenuPage.value = true;
    await buildMainMenu(tester);
    expect(
      tester.getSize(find.byKey(const ValueKey('choice-foodDrink'))).height,
      tester.getSize(find.byKey(const ValueKey('choice-music'))).height,
      reason: 'Reduced motion keeps the artwork at a constant size',
    );
    await move(tester, 'Previous');
    expect(find.text('Nearby'), findsOneWidget);
    await move(tester, 'Next');
    expect(find.text('Food & Drink'), findsOneWidget);
    staticMainMenuPage.value = false;
  });

  testWidgets(
      'resizes the carousel and preserves selection across device sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await buildMainMenu(tester);
    final phoneHeight = tester.getSize(find.byType(PageView)).height;
    expect(find.byKey(const ValueKey('selected-category')).hitTestable(),
        findsOneWidget);
    await move(tester, 'Next');

    tester.view.physicalSize = const Size(1024, 1366);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height,
        greaterThanOrEqualTo(phoneHeight));
    expect(tester.getSize(find.byType(PageView)).width, lessThanOrEqualTo(680));
    expect(find.text('Music'), findsOneWidget);
    expect(find.byKey(const ValueKey('selected-category')).hitTestable(),
        findsOneWidget);

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
    expect(find.text('Shopping & Stalls'), findsOneWidget);
  });

  testWidgets('small phones show complete captions without scrolling',
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
      await buildMainMenu(tester);
      for (var i = 0; i < 8; i++) {
        final outerScroll = tester.state<ScrollableState>(find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first);
        expect(outerScroll.position.maxScrollExtent, 0,
            reason: 'The whole main menu should fit at $size, category $i');
        final next = find.byType(BottomNavigationBar);
        expect(next.hitTestable(), findsOneWidget);
        final caption = find.byKey(const ValueKey('selected-category'));
        final rect = tester.getRect(caption);
        expect(rect.bottom, lessThanOrEqualTo(tester.getRect(next).top));
        expect(
            rect.top, greaterThan(tester.getRect(find.byType(AppBar)).bottom));
        await move(tester, 'Next');
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
    await buildMainMenu(tester, theme: appThemes['dark'], textScale: 2);
    for (var i = 0; i < 8; i++) {
      await move(tester, 'Next');
      expect(tester.takeException(), isNull);
    }
    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    await move(tester, 'Previous');
    expect(find.text('Nearby'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
