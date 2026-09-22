import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

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
        'performance': 'FALSE',
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

  Future<MapPageState> openMap(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: MapPage(
      listings: listings,
      onTabSelected: (_) {},
      analyticsService: FakeAnalyticsService(),
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
    expect(find.byIcon(Icons.assistant_navigation), findsNothing);
    expect(find.text('Road closures'), findsNothing);
    expect(find.byTooltip('Switch to satellite view'), findsOneWidget);
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
  testWidgets('destination card floats over the map with camera clearance with matching border and clears on cancel', (tester) async {
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
    expect(padding, greaterThanOrEqualTo(mapBounds.bottom - bounds.top));
    expect(state.mapHeight, closeTo(mapBounds.height - padding, 1));
    expect(bounds.overlaps(tester.getRect(find.byTooltip('Switch to satellite view'))), isFalse);
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

  testWidgets('saved satellite style has correct icon and toggles both ways during navigation', (tester) async {
    // Set firstExecution to false to simulate normal app launch
    firstExecution = false;

    preferredMapStyleType = MapStyleType.hybrid;
    final state = await openMap(tester);
    await navigate(tester, state);
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).mapType, MapType.hybrid);
    expect(find.descendant(of: find.byTooltip('Switch to normal map'), matching: find.byIcon(Icons.map)), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to normal map'));
    await tester.pumpAndSettle();
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).mapType, MapType.normal);
    expect(preferredMapStyleType, MapStyleType.normal);
    await tester.tap(find.byTooltip('Switch to satellite view'));
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
    expect(bounds.height, greaterThanOrEqualTo(64));
    expect(tester.widget<Text>(find.text('250 m')).style!.fontSize, greaterThanOrEqualTo(26));
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
