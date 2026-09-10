import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('fluttertoast'),
      (_) async => true,
    );
  });

  tearDown(() {
    navigationInProgress = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('fluttertoast'),
      null,
    );
  });

  Future<MapPageState> openMap(WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(home: MapPage(listings: listings, onTabSelected: (_) {})));
    await tester.pumpAndSettle();
    return tester.state<MapPageState>(find.byType(MapPage));
  }

  Future<void> navigate(WidgetTester tester, MapPageState state) async {
    // No location fix: exercise destination selection without live routing/GPS.
    currentLatLng = null;
    await state.doTheNavigation(
        'destination', const LatLng(52.199687, 0.138813), false);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'destination card shows listing details at top right with matching border and clears on cancel',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = await openMap(tester);
    expect(find.text('Navigating to'), findsNothing);
    await navigate(tester, state);

    for (final text in [
      'Navigating to',
      '🍩 Glazed and Confused',
      'Doughnuts',
      'Gwydir St Car Park',
      '11:00–15:00'
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    final card = find
        .ancestor(
            of: find.text('Navigating to'), matching: find.byType(Material))
        .first;
    final shape =
        tester.widget<Material>(card).shape! as RoundedRectangleBorder;
    expect(
        shape.side,
        BorderSide(
            color: Theme.of(tester.element(card)).colorScheme.primary,
            width: 0.5));
    final bounds = tester.getRect(card);
    final mapBounds = tester.getRect(find.byType(GoogleMap));
    expect(bounds.right, closeTo(mapBounds.right - 8, 1));
    expect(bounds.top, closeTo(mapBounds.top + 8, 1));
    expect(bounds.width, lessThanOrEqualTo(260));
    expect(
        bounds.overlaps(
            tester.getRect(find.byTooltip('Switch to satellite view'))),
        isFalse);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();
    expect(find.text('Navigating to'), findsNothing);
  });

  testWidgets(
      'destination card omits missing optional fields and supports a single time',
      (tester) async {
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

  testWidgets(
      'saved satellite style has correct icon and toggles both ways during navigation',
      (tester) async {
    preferredMapStyleType = MapStyleType.hybrid;
    final state = await openMap(tester);
    await navigate(tester, state);
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).mapType,
        MapType.hybrid);
    expect(
        find.descendant(
            of: find.byTooltip('Switch to normal map'),
            matching: find.byIcon(Icons.map)),
        findsOneWidget);
    await tester.tap(find.byTooltip('Switch to normal map'));
    await tester.pumpAndSettle();
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).mapType,
        MapType.normal);
    expect(preferredMapStyleType, MapStyleType.normal);
    await tester.tap(find.byTooltip('Switch to satellite view'));
    await tester.pumpAndSettle();
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).mapType,
        MapType.hybrid);
    expect(preferredMapStyleType, MapStyleType.hybrid);
    expect(find.text('Navigating to'), findsOneWidget);
  });

  testWidgets(
      'distance control is large, bottom centred, safe from system inset and tappable',
      (tester) async {
    var taps = 0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(
          size: Size(390, 844), padding: EdgeInsets.only(bottom: 40)),
      child: Scaffold(
          body: NavigationDistanceButton(
              distance: '250 m', onPressed: () => taps++)),
    )));
    final button = find.byType(ElevatedButton);
    final bounds = tester.getRect(button);
    expect(bounds.center.dx, closeTo(195, 1));
    expect(bounds.bottom, closeTo(804, 1));
    expect(bounds.width, greaterThanOrEqualTo(180));
    expect(bounds.height, greaterThanOrEqualTo(64));
    expect(tester.widget<Text>(find.text('250 m')).style!.fontSize,
        greaterThanOrEqualTo(26));
    await tester.tap(button);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
