import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

class NavigationAnalytics extends FakeAnalyticsService {
  final events = <Map<String, String?>>[];

  @override
  Future<void> logButtonTapped(String buttonName, {String? listingId, String? listingName}) async {
    events.add({'button': buttonName, 'id': listingId, 'name': listingName});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    onTest = true;
    await loadSettings();
    navigationInProgress = false;
    currentLatLng = null;
    locationServicesEnabled = true;
    locationPermission = LocationPermission.always;
    preferredMapStyleType = MapStyleType.normal;
    listings = [
      {
        'id': 'destination',
        'emoji': '🍩',
        'title': 'Glazed and Confused',
        'subtitle': 'Doughnuts',
        'location': 'Gwydir St Car Park',
        'startTime': '11:00',
        'endTime': '15:00',
        'latLng': '52.199687,0.138813',
        'visibleOnMap': 'TRUE',
        'cancelled': 'FALSE',
        'groupParent': 'FALSE',
        'brickAndMortar': 'FALSE',
        'groupID': '',
        'food': 'TRUE',
        'shopping': 'FALSE',
        'charityCommunityInfo': 'FALSE',
        'performanceMusic': 'FALSE',
        'performanceChildrens': 'FALSE',
        'performanceDance': 'FALSE',
        'performanceOther': 'FALSE',
        'business': 'FALSE',
        'visitExperience': 'FALSE',
        'service': 'FALSE',
      },
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('fluttertoast'),
      (_) async => true,
    );
  });

  tearDown(() {
    navigationInProgress = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('fluttertoast'),
      null,
    );
  });

  Future<MapPageState> openMap(WidgetTester tester, {AnalyticsService? analytics}) async {
    await tester.pumpWidget(MaterialApp(
        home: MapPage(
      listings: listings,
      onTabSelected: (_) {},
      analyticsService: analytics ?? FakeAnalyticsService(),
    )));
    await tester.pumpAndSettle();
    return tester.state<MapPageState>(find.byType(MapPage));
  }

  Future<void> navigate(WidgetTester tester, MapPageState state) async {
    // No location fix: exercise destination selection without live routing/GPS.
    currentLatLng = null;
    await state.doTheNavigation('destination', const LatLng(52.199687, 0.138813), false);
    await tester.pumpAndSettle();
  }

  testWidgets('directions from the map opens its own route and leaves the map unchanged', (tester) async {
    firstExecution = false;
    final original = await openMap(tester);
    final originalMarkers = Map.of(original.markers);
    final routeClosed = original.getDirections('destination', const LatLng(52.199687, 0.138813), false);
    await tester.pumpAndSettle();

    expect(find.text('Directions'), findsOneWidget);
    expect(find.byIcon(Icons.filter_alt), findsNothing);
    expect(find.byIcon(Icons.search), findsNothing);
    expect(find.byIcon(Icons.assistant_navigation), findsNothing);
    expect(find.text('Road closures'), findsNothing);
    expect(find.byTooltip('Switch to satellite map'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(original.navigationInProgress, isFalse);
    expect(original.markers, originalMarkers);
    expect(tester.state<MapPageState>(find.byType(MapPage)), isNot(same(original)));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await routeClosed;
    expect(tester.state<MapPageState>(find.byType(MapPage)), same(original));
    expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    expect(find.text('Navigating to'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning from directions preserves the map search and its camera space', (tester) async {
    firstExecution = false;
    final original = await openMap(tester);
    expect(find.byIcon(Icons.radar), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    final field = find.descendant(of: find.byType(SearchBar), matching: find.byType(TextField));
    await tester.enterText(field, 'glazed');
    await tester.pumpAndSettle();
    expect(original.mapHeight, closeTo(tester.getSize(find.byType(GoogleMap)).height - 56, 1));
    final originalMarkers = Map.of(original.markers);

    final closed = original.getDirections('destination', const LatLng(52.199687, 0.138813), false);
    await tester.pumpAndSettle();
    expect(find.byType(SearchBar), findsNothing);
    expect(find.byIcon(Icons.search), findsNothing);
    expect(find.byIcon(Icons.radar), findsNothing);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await closed;
    expect(tester.widget<TextField>(field).controller!.text, 'glazed');
    expect(original.markers, originalMarkers);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation keeps only the destination visible and tolerates a missing listing', (tester) async {
    firstExecution = false;
    listings.add({...listings.first, 'id': 'other', 'title': 'Another venue'});
    final state = await openMap(tester);
    await navigate(tester, state);
    expect(state.markers.values.where((marker) => marker.visible).map((marker) => marker.markerId.value), ['destination']);
    state.cancelNavigation();
    await tester.pumpAndSettle();
    currentLatLng = null;
    await state.doTheNavigation('removed-listing', const LatLng(52.199687, 0.138813), false);
    await tester.pumpAndSettle();
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Navigating to'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('destination card overlays the map without changing camera space and clears on cancel', (tester) async {
    // Set firstExecution to false to simulate normal app launch
    firstExecution = false;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = await openMap(tester);
    expect(find.text('Navigating to'), findsNothing);
    await navigate(tester, state);

    for (final text in ['Navigating to', '🍩 Glazed and Confused', 'Doughnuts', 'Gwydir St Car Park', '11:00–15:00']) {
      expect(find.text(text), findsOneWidget);
    }
    final card = find.ancestor(of: find.text('Navigating to'), matching: find.byType(Material)).first;
    final shape = tester.widget<Material>(card).shape! as RoundedRectangleBorder;
    expect(shape.side, BorderSide(color: Theme.of(tester.element(card)).colorScheme.primary, width: 0.5));
    final bounds = tester.getRect(card);
    final mapBounds = tester.getRect(find.byType(GoogleMap));
    expect(bounds.left, closeTo(mapBounds.left + 12, 1));
    expect(bounds.bottom, lessThanOrEqualTo(mapBounds.bottom - 12));
    final padding = tester.widget<GoogleMap>(find.byType(GoogleMap)).padding.bottom;
    expect(padding, 0);
    expect(state.mapHeight, closeTo(mapBounds.height, 1));
    expect(bounds.overlaps(tester.getRect(find.byTooltip('Switch to satellite map'))), isFalse);
    expect(tester.takeException(), isNull);

    // Completing/repeating normal map initialisation must not clear the destination.
    state.addAllVisibleMarkers();
    await tester.pumpAndSettle();
    expect(state.markers[const MarkerId('destination')]?.visible, isTrue);
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).markers.any((marker) => marker.markerId.value == 'destination' && marker.visible), isTrue);
    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();
    expect(find.text('Navigating to'), findsNothing);
  });

  testWidgets('destination card omits missing optional fields and supports a single time', (tester) async {
    // Set firstExecution to false to simulate normal app launch
    firstExecution = false;

    listings.first.remove('emoji');
    listings.first.remove('subtitle');
    listings.first['location'] = '  ';
    listings.first.remove('endTime');
    final state = await openMap(tester);
    await navigate(tester, state);
    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('11:00'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
    expect(find.byIcon(Icons.place_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination details initially collapse then stay open until manually minimised', (tester) async {
    var distanceTaps = 0;
    final actions = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: NavigationBottomRow(
            destinationCard: const SizedBox(height: 150, child: Text('Destination details')),
            distance: '250 m',
            onDistancePressed: () => distanceTaps++,
            onDestinationExpanded: () => actions.add('expand'),
            onDestinationMinimised: () => actions.add('minimise'),
          ),
        ),
      ),
    ));
    final expandedBounds = tester.getRect(find.byType(AnimatedSize));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Destination details'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 175));
    final animatedBounds = tester.getRect(find.byType(AnimatedSize));
    expect(animatedBounds.width, lessThan(expandedBounds.width));
    expect(animatedBounds.width, greaterThan(204));
    await tester.pumpAndSettle();
    expect(find.text('Destination details'), findsNothing);
    expect(find.byTooltip('Show destination details'), findsOneWidget);
    final collapsedBounds = tester.getRect(find.byType(AnimatedSize));
    expect(collapsedBounds.left, closeTo(expandedBounds.left, 1));
    expect(collapsedBounds.width, 204);
    final destinationButton = find.byTooltip('Show destination details');
    expect(tester.getSize(destinationButton), const Size(48, 48));
    final buttonMaterial = tester.widget<Material>(find.ancestor(of: destinationButton, matching: find.byType(Material)).first);
    expect(buttonMaterial.shape, isA<CircleBorder>());
    expect(actions, isEmpty);
    await tester.tap(find.byType(NavigationDistanceButton));
    expect(distanceTaps, 1);

    await tester.tap(find.byTooltip('Show destination details'));
    await tester.pumpAndSettle();
    expect(find.text('Destination details'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Destination details'), findsOneWidget);
    expect(actions, ['expand']);
    await tester.tap(find.text('Minimise'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show destination details'), findsOneWidget);
    expect(actions, ['expand', 'minimise']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination analytics record manual actions with listing context', (tester) async {
    firstExecution = false;
    final analytics = NavigationAnalytics();
    final state = await openMap(tester, analytics: analytics);
    await navigate(tester, state);
    // Minimise before the initial timer expires, then reopen and stay open.
    await tester.tap(find.text('Minimise'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show destination details'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Navigating to'), findsOneWidget);
    expect(analytics.events, [
      {'button': 'destination_card_minimise', 'id': 'destination', 'name': 'Glazed and Confused'},
      {'button': 'destination_card_expand', 'id': 'destination', 'name': 'Glazed and Confused'},
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved satellite style has correct icon and toggles both ways during navigation', (tester) async {
    // Set firstExecution to false to simulate normal app launch
    firstExecution = false;

    preferredMapStyleType = MapStyleType.hybrid;
    final state = await openMap(tester);
    await navigate(tester, state);
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).mapType, MapType.hybrid);
    expect(find.descendant(of: find.byTooltip('Switch to street map'), matching: find.byIcon(Icons.map)), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to street map'));
    await tester.pumpAndSettle();
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).mapType, MapType.normal);
    expect(preferredMapStyleType, MapStyleType.normal);
    await tester.tap(find.byTooltip('Switch to satellite map'));
    await tester.pumpAndSettle();
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).mapType, MapType.hybrid);
    expect(preferredMapStyleType, MapStyleType.hybrid);
    expect(find.text('Navigating to'), findsOneWidget);
  });

  testWidgets('navigation row keeps both controls below the map and above the system inset', (tester) async {
    var taps = 0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.only(bottom: 40)),
      child: Scaffold(body: Column(children: [
        const Expanded(child: SizedBox(key: ValueKey('map-area'), width: double.infinity)),
        NavigationBottomRow(
          destinationCard: const SizedBox(height: 150, child: Text('Destination details')),
          distance: '250 m',
          onDistancePressed: () => taps++,
        ),
      ])),
    )));
    final button = find.byType(ElevatedButton);
    final bounds = tester.getRect(button);
    final sharedCard = find.ancestor(of: find.text('Destination details'), matching: find.byType(Material)).first;
    expect(find.descendant(of: sharedCard, matching: find.byType(NavigationDistanceButton)), findsOneWidget);
    final cardBounds = tester.getRect(find.text('Destination details'));
    final mapBounds = tester.getRect(find.byKey(const ValueKey('map-area')));
    expect(bounds.left, greaterThan(cardBounds.right));
    expect(bounds.top, greaterThan(mapBounds.bottom));
    expect(cardBounds.top, greaterThan(mapBounds.bottom));
    expect(bounds.bottom, lessThanOrEqualTo(804));
    expect(tester.getRect(find.byType(NavigationBottomRow)).bottom, closeTo(844, 1));
    expect(bounds.height, 48);
    final minimiseBounds = tester.getRect(find.widgetWithText(TextButton, 'Minimise'));
    expect(minimiseBounds.top, greaterThanOrEqualTo(bounds.bottom));
    expect(minimiseBounds.left, closeTo(bounds.left, 1));
    expect(minimiseBounds.right, closeTo(bounds.right, 1));
    expect(bounds.right, closeTo(tester.getRect(sharedCard).right - 12, 1));
    expect(tester.widget<Text>(find.text('250 m')).style!.fontSize, 16);
    await tester.tap(button);
    expect(taps, 1);
    expect(tester.takeException(), isNull);

    // Both controls remain alongside one another on a small phone.
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();
    final narrowButton = tester.getRect(button);
    final narrowCard = tester.getRect(find.text('Destination details'));
    expect(narrowButton.left, greaterThan(narrowCard.right));
    expect(narrowButton.right, lessThanOrEqualTo(308));
    expect(narrowButton.top, greaterThan(tester.getRect(find.byKey(const ValueKey('map-area'))).bottom));
    expect(tester.takeException(), isNull);
  });
}
