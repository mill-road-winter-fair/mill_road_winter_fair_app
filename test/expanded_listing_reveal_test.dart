import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/expanded_listing_reveal.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  testWidgets(
      'the actual listings page allows scrolling while details stay open',
      (tester) async {
    onTest = true;
    locationPermission = LocationPermission.denied;
    locationServicesEnabled = false;
    await loadSettings();
    listings = [
      {
        'id': 'scrollable',
        'title': 'Listing',
        'subtitle': 'Stall',
        'location': 'Mill Road',
        'groupParent': 'FALSE',
        'cancelled': 'FALSE',
        'brickAndMortar': 'FALSE',
        'description': List.filled(150, 'Long details.').join(' '),
        'email': '',
        'website': '',
        'phone': '01223 123456',
        'imageURL': '',
        'latLng': '52.199687,0.138813',
        'startTime': '10:00',
        'endTime': '23:59',
      }
    ];
    await tester.pumpWidget(MaterialApp(
        home: FilteredListingsPage(
      filterCategory: 'all',
      listings: listings,
      onTabSelected: (_) {},
      onSubfilterChange: (_) {},
      analyticsService: FakeAnalyticsService(),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.info));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('Telephone:'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Telephone:').hitTestable(), findsOneWidget);
    expect(
        tester
            .state<FilteredListingsPageState>(find.byType(FilteredListingsPage))
            .detailsVisibleIndex,
        0);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in [const Size(320, 240), const Size(800, 600)]) {
    for (final positioned in [false, true]) {
      testWidgets(
          'reveals only clipped content in $viewport (positioned: $positioned)',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bounds = ExpandedListingScrollBounds();
        var expanded = false;
        var contentHeight = 60.0;
        late StateSetter update;
        const cardKey = ValueKey('card');
        await tester
            .pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            final children = [
              SizedBox(height: viewport.height / 2),
              ExpandedListingReveal(
                expanded: expanded,
                bounds: bounds,
                child: SizedBox(
                    key: cardKey,
                    height: contentHeight,
                    child: const Text('Details')),
              ),
              SizedBox(height: viewport.height * 2),
            ];
            return positioned
                ? ScrollablePositionedList.builder(
                    physics: ExpandedListingScrollPhysics(bounds: bounds),
                    itemCount: children.length,
                    itemBuilder: (_, i) => children[i])
                : ListView(
                    physics: ExpandedListingScrollPhysics(
                        bounds: bounds, parent: const BouncingScrollPhysics()),
                    children: children);
          },
        ))));
        await tester.pumpAndSettle();
        final originalTop = tester.getTopLeft(find.byKey(cardKey)).dy;
        update(() => expanded = true);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byKey(cardKey)).dy, originalTop);

        await tester.flingFrom(Offset(viewport.width / 2, viewport.height / 2),
            Offset(0, -viewport.height * 2), 2500);
        await tester.pumpAndSettle();
        // A short tile can move slightly past the edge, but half stays visible.
        expect(tester.getTopLeft(find.byKey(cardKey)).dy, closeTo(-30, 1));
        expect(tester.getBottomLeft(find.byKey(cardKey)).dy, closeTo(30, 1));
        await tester.flingFrom(Offset(viewport.width / 2, viewport.height / 2),
            Offset(0, viewport.height * 2), 2500);
        await tester.pumpAndSettle();
        expect(tester.getBottomLeft(find.byKey(cardKey)).dy,
            closeTo(originalTop + contentHeight, 1));

        // Reopening restores automatic positioning for the late-image checks.
        update(() => expanded = false);
        await tester.pumpAndSettle();
        update(() => expanded = true);
        await tester.pumpAndSettle();

        // A delayed image changes the card's size after expansion.
        update(() => contentHeight = viewport.height * .75);
        await tester.pumpAndSettle();
        expect(tester.getBottomLeft(find.byKey(cardKey)).dy,
            closeTo(viewport.height, 1));
        expect(tester.getTopLeft(find.byKey(cardKey)).dy, greaterThan(0));

        update(() => contentHeight = viewport.height * 1.5);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byKey(cardKey)).dy, closeTo(0, 1));
        await tester.drag(find.byKey(cardKey), const Offset(0, -50));
        await tester.pumpAndSettle();
        final manualTop = tester.getTopLeft(find.byKey(cardKey)).dy;
        expect(manualTop, lessThan(0));
        update(() => contentHeight += 40);
        await tester.pumpAndSettle();
        expect(
            tester.getTopLeft(find.byKey(cardKey)).dy, closeTo(manualTop, 1));

        // Large flings cannot leave the expanded tile behind in either direction.
        final leeway = (viewport.height * .2).clamp(0.0, 120.0);
        await tester.flingFrom(Offset(viewport.width / 2, viewport.height / 2),
            Offset(0, -viewport.height * 2), 2500);
        await tester.pumpAndSettle();
        expect(tester.getBottomLeft(find.byKey(cardKey)).dy,
            closeTo(viewport.height - leeway, 1));
        await tester.flingFrom(Offset(viewport.width / 2, viewport.height / 2),
            Offset(0, viewport.height * 2), 2500);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byKey(cardKey)).dy, closeTo(leeway, 1));
        update(() => expanded = false);
        await tester.pumpAndSettle();
        await tester.dragFrom(Offset(viewport.width / 2, viewport.height / 2),
            Offset(0, -viewport.height * 1.25));
        await tester.pumpAndSettle();
        expect(tester.getBottomLeft(find.byKey(cardKey)).dy,
            lessThan(viewport.height));
        update(() => expanded = true);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byKey(cardKey)).dy, closeTo(0, 1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
