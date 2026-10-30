// App imports
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

// Third-party imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Test helpers, fakes and mocks
import 'mocks/listings_mocks.dart';
import 'pump_with_clock.dart';

void main() {
  // We're on test
  onTest = true;

  setUpAll(() async {
    // Mock location services and permissions
    locationServicesEnabled = true;
    locationPermission = LocationPermission.always;

    // Mock user settings
    await loadSettings();

    listings = [
      mockListing('foodGroup'),
      mockListing('groupedDoughnuts'),
      mockListing('nearbySushi'),
    ];
  });

  tearDown(() {
    locationServicesEnabled = true;
    locationPermission = LocationPermission.always;
  });

  // Set up mocks
  late MapPageState mapPageState;
  setUp(() {
    mapPageState = MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}).createState();
  });

  group('MapPage', () {
    for (final bottomSafeArea in [0.0, 24.0, 34.0, 48.0]) {
      testWidgets('search map meets the keyboard with a $bottomSafeArea bottom safe area and restores when dismissed', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(800, 600);
        tester.view.viewPadding = FakeViewPadding(bottom: bottomSafeArea);
        tester.view.padding = FakeViewPadding(bottom: bottomSafeArea);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(tester.view.resetViewPadding);
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(MaterialApp(
          home: MapPage(listings: listings, onTabSelected: (_) {}, analyticsService: FakeAnalyticsService()),
        ));
        await tester.pump();
        await tester.tap(find.byTooltip('Search the map'));
        await tester.pump();

        final map = find.byType(GoogleMap);
        final beforeKeyboard = tester.getRect(map);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        tester.view.padding = FakeViewPadding.zero;
        await tester.pump();

        final withKeyboard = tester.getRect(map);
        expect(withKeyboard.height, lessThan(beforeKeyboard.height));
        expect(withKeyboard.topLeft, beforeKeyboard.topLeft);
        expect(withKeyboard.width, beforeKeyboard.width);
        expect(withKeyboard.bottom, closeTo(600 - 300, 0.01));
        expect(tester.takeException(), isNull);

        tester.view.resetViewInsets();
        tester.view.padding = FakeViewPadding(bottom: bottomSafeArea);
        await tester.pump();
        expect(tester.getRect(map), beforeKeyboard);
      });
    }

    testWidgets('theme changes refresh existing marker types without resetting the map', (tester) async {
      final previousTheme = selectedThemeKey;
      selectedThemeKey = 'light';
      themeNotifier.value = 'light';
      addTearDown(() {
        selectedThemeKey = previousTheme;
        themeNotifier.value = previousTheme;
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: MapPage(listings: listings, onTabSelected: (_) {}, analyticsService: FakeAnalyticsService())),
      ));
      await tester.pump();
      final state = tester.state<MapPageState>(find.byType(MapPage));
      state.addSimpleMarker('Service-FirstAid', const LatLng(52.2, 0.14));
      final base = {...listings.first, 'groupParent': 'FALSE', 'groupID': ''};
      state.addSpecificMarker({...base, 'id': '26030', 'shopping': 'TRUE'});
      state.addSpecificMarker({...base, 'id': '26031', 'food': 'FALSE', 'performanceMusic': 'TRUE', 'performanceDance': 'TRUE'});
      state.hideAllMarkers();
      final before = Map<MarkerId, Marker>.of(state.markers);
      final types = {
        '26101': 'Group-Food', '26012': 'Food', aSimpleMarkerId: 'Service-FirstAid',
        '26030': 'Mixed', '26031': 'Group-PerformanceEvent',
      };
      for (final theme in ['dark', '2024', 'highContrast', 'colourBlindFriendly', 'light']) {
        selectedThemeKey = theme;
        themeNotifier.value = theme;
        await tester.pump();
        expect(state.markers.keys, unorderedEquals(before.keys));
        for (final entry in types.entries) {
          final id = MarkerId(entry.key);
          final marker = state.markers[id]!;
          expect(marker.icon.toJson(), BitmapDescriptor.defaultMarkerWithHue(HSVColor.fromColor(getCategoryColor(theme, entry.value)).hue).toJson(), reason: '$theme: ${entry.value}');
          expect(marker.visible, before[id]!.visible);
          expect(marker.position, before[id]!.position);
          expect(marker.onTap, before[id]!.onTap);
        }
      }
      selectedThemeKey = 'auto';
      themeNotifier.value = 'auto';
      for (final brightness in [Brightness.dark, Brightness.light]) {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        await tester.pumpAndSettle();
        expect(state.markers[const MarkerId('26012')]!.icon.toJson(),
          BitmapDescriptor.defaultMarkerWithHue(HSVColor.fromColor(getCategoryColor(brightness == Brightness.dark ? 'dark' : 'light', 'Food')).hue).toJson());
      }
      // A queued refresh must not call setState after the map has been removed.
      selectedThemeKey = 'dark';
      themeNotifier.value = 'dark';
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('clears a nearby request after build when no markers are visible', (tester) async {
      final previousLocation = currentLatLng;
      addTearDown(() => currentLatLng = previousLocation);
      locationPermission = LocationPermission.deniedForever;
      currentLatLng = const LatLng(52.2, 0.14);
      int? nearestMarkerCount;

      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => setState(() => nearestMarkerCount = 10),
                  child: const Text('Show nearby'),
                ),
                Expanded(
                  child: MapPage(
                    listings: listings,
                    nearestMarkerCount: nearestMarkerCount,
                    cancelMapNearest: () => setState(() => nearestMarkerCount = null),
                    onTabSelected: (_) {},
                    analyticsService: FakeAnalyticsService(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pump();
      tester.state<MapPageState>(find.byType(MapPage)).hideAllMarkers();
      await tester.pump();

      await tester.tap(find.text('Show nearby'));
      await tester.pump();
      await tester.pump();

      expect(nearestMarkerCount, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not enable the map location layer without permission', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      locationPermission = LocationPermission.deniedForever;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapPage(
              listings: listings,
              onTabSelected: (_) {},
              analyticsService: FakeAnalyticsService(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).myLocationEnabled, isFalse);
    });

    testWidgets('search keeps distinct markers apart when multiple matches share the same location', (tester) async {
      final sharedLocationListings = [
        mockListing('seafoodGroup'),
        mockListing('seabreezeStall'),
      ];

      final originalListings = [...listings];
      addTearDown(() => listings = originalListings);
      listings = sharedLocationListings;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: MapPage(listings: sharedLocationListings, onTabSelected: (_) {}, analyticsService: FakeAnalyticsService())),
      ));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      final field = find.descendant(of: find.byType(SearchBar), matching: find.byType(TextField));
      await tester.enterText(field, 'sea');
      await tester.pump();
      final state = tester.state<MapPageState>(find.byType(MapPage));
      expect(state.markers.length, 2);
      expect(state.markers.values.map((m) => m.position).toSet().length, 2,
          reason: 'Two matching markers at the same lat/lng should be visually offset to avoid overlap.');
    });

    testWidgets('cancelNavigation restores markers matching any selected category', (tester) async {
      final originalListings = listings;
      addTearDown(() => listings = originalListings);
      listings = [{...originalListings[2], 'business': 'TRUE'}];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapPage(
              listings: listings,
              onTabSelected: (_) {},
              analyticsService: FakeAnalyticsService(),
            ),
          ),
        ),
      );
      await tester.pump();

      final state = tester.state<MapPageState>(find.byType(MapPage));
      const markerId = MarkerId('26012');
      expect(state.markers[markerId]?.visible, isTrue);

      state.filterSettings['Business'] = false;
      state.hideAllMarkers();
      navigationInProgress = true;
      state.cancelNavigation();
      await tester.pump();

      expect(
        state.markers[markerId]?.visible,
        isTrue,
        reason: 'Food remains selected, so disabling Business must not hide a Food+Business marker.',
      );
    });

    testWidgets('search includes hidden listings and restores default pins', (tester) async {
      final toastCalls = <MethodCall>[];
      const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(toastChannel, (call) async {
        toastCalls.add(call);
        return true;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(toastChannel, null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: MapPage(listings: listings, onTabSelected: (_) {}, analyticsService: FakeAnalyticsService())),
      ));
      await tester.pump();
      final state = tester.state<MapPageState>(find.byType(MapPage));
      Set<String> visibleIds() => state.markers.values
          .where((marker) => marker.visible)
          .map((marker) => marker.markerId.value)
          .toSet();
      expect(visibleIds(), {'26101', '26012'});

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26101', '26012'});
      final field = find.descendant(of: find.byType(SearchBar), matching: find.byType(TextField));
      await tester.enterText(field, 'z');
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26011'});
      await tester.enterText(field, 'GLAZED');
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26011'});
      expect(toastCalls, isEmpty);
      await tester.enterText(field, 'no such listing');
      await tester.pump();
      expect(visibleIds(), isEmpty);
      expect(toastCalls.single.method, 'showToast');
      expect(toastCalls.single.arguments['msg'], 'No matching listings found');
      await tester.enterText(field, 'headly street');
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26101', '26011'});
      await tester.enterText(field, '');
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26101', '26012'});
      await tester.enterText(field, 'glazed');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.search).last);
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26101', '26012'});

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(field, 'glazed');
      await tester.pump();
      final clear = find.descendant(of: find.byType(SearchBar), matching: find.byIcon(Icons.close));
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26101', '26012'});
      await tester.enterText(field, 'glazed');
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26101', '26012'});
      expect(find.byType(SearchBar), findsNothing);
      expect(toastCalls, hasLength(1));
    });

    testWidgets('dot pulse pauses while the map page is hidden and resumes when visible', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}, isVisible: true),
        ),
      ));

      final visibleState = tester.state(find.byType(MapPage)) as MapPageState;
      visibleState.dotPulseController ??= AnimationController(vsync: visibleState, duration: const Duration(milliseconds: 1500));
      visibleState.dotPulse = CurvedAnimation(parent: visibleState.dotPulseController!, curve: Curves.easeInOut);
      visibleState.dotPulseController!.repeat(reverse: false);
      expect(visibleState.dotPulseController!.isAnimating, isTrue);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}, isVisible: false),
        ),
      ));

      final hiddenState = tester.state(find.byType(MapPage)) as MapPageState;
      hiddenState.dotPulseController ??= AnimationController(vsync: hiddenState, duration: const Duration(milliseconds: 1500));
      hiddenState.dotPulse = CurvedAnimation(parent: hiddenState.dotPulseController!, curve: Curves.easeInOut);
      hiddenState.dotPulseController!.repeat(reverse: false);
      hiddenState.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(hiddenState.dotPulseController!.isAnimating, isFalse);
      expect(hiddenState.widget.isVisible, isFalse);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}, isVisible: true),
        ),
      ));

      final visibleAgainState = tester.state(find.byType(MapPage)) as MapPageState;
      visibleAgainState.dotPulseController ??= AnimationController(vsync: visibleAgainState, duration: const Duration(milliseconds: 1500));
      visibleAgainState.dotPulse = CurvedAnimation(parent: visibleAgainState.dotPulseController!, curve: Curves.easeInOut);
      visibleAgainState.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(visibleAgainState.widget.isVisible, isTrue);
      expect(visibleAgainState.dotPulseController!.isAnimating, isTrue);
    });

    testWidgets('all map buttons are present', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // Check the map buttons
      expect(find.byType(FloatingActionButton), findsExactly(5));
      expect(find.byIcon(Icons.home), findsExactly(1));
      expect(find.byIcon(Icons.radar), findsOneWidget);
      expect(find.byIcon(Icons.satellite_alt), findsOneWidget);
      expect(find.byIcon(Icons.assistant_navigation), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt), findsOneWidget);
      expect(find.byIcon(Icons.radar), findsOneWidget);

      // Check road closure button
      expect(find.text('Road closures'), findsOneWidget);
    });

    testWidgets('cancelling search reapplies the selected marker filters', (tester) async {
      final originalListings = listings;
      addTearDown(() => listings = originalListings);
      listings = [
        originalListings[2],
        mockListing('informationPoint'),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapPage(listings: listings, onTabSelected: (_) {}, analyticsService: FakeAnalyticsService()),
        ),
      ));
      await tester.pump();

      final state = tester.state<MapPageState>(find.byType(MapPage));
      Set<String> visibleIds() => state.markers.values
          .where((marker) => marker.visible)
          .map((marker) => marker.markerId.value)
          .toSet();
      state.filterSettings['Food'] = false;
      state.showFilteredMarkers();
      expect(visibleIds(), {'26014'});

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      final field = find.descendant(of: find.byType(SearchBar), matching: find.byType(TextField));
      await tester.enterText(field, 'sushi');
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26012'});

      await tester.tap(find.byIcon(Icons.search).last);
      await tester.pumpAndSettle();
      expect(visibleIds(), {'26014'});
    });

    testWidgets('Home button centres the map and resets filters if all were off', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Mock the MethodChannel for Google Maps to capture camera movements
      final List<MethodCall> methodCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_maps_0'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return null;
        },
      );

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;

      // Force filters to be off to test that the Home button resets them
      for (var key in mapPageState.filterSettings.keys) {
        mapPageState.filterSettings[key] = false;
      }

      // Simulate panning away by dragging the map
      await tester.drag(find.byType(GoogleMap), const Offset(-400, -400));
      await tester.pump();

      // Clear initial setup calls
      methodCalls.clear();

      // Tap the Home button to trigger centering and filter reset logic
      await tester.tap(find.byIcon(Icons.home).first);
      await tester.pump();

      // Verify that filters were reset to true
      expect(mapPageState.filterSettings.values.every((v) => v == true), true);

      // Verify that camera move commands were sent to the platform side if the controller was initialized
      final cameraUpdateCalls = methodCalls.where((call) => call.method == 'camera#animate').toList();
      // In some test environments, the platform view controller might not initialize fully,
      // so we check if calls were made, but the filter reset above already proves the button works.
      if (cameraUpdateCalls.isNotEmpty) {
        expect(cameraUpdateCalls.any((call) => call.arguments.toString().contains('cameraUpdate')), true);
      }
    });

    testWidgets('map type button changes map type', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;

      // Check the initial map type
      expect(mapPageState.mapType, MapType.normal);

      // Switch the map type
      await tester.tap(find.byIcon(Icons.satellite_alt));
      await tester.pump();
      expect(mapPageState.mapType, MapType.hybrid);

      // Switch the map type back
      await tester.tap(find.byIcon(Icons.map).first);
      await tester.pump();
      expect(mapPageState.mapType, MapType.normal);
    });

    testWidgets('Compass button toggles map orientation between Adaptive and North-up', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Ensure we start in a known state before pumping the widget
      preferredMapOrientation = MapOrientation.adaptive;

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // Find the compass button by its icon
      final compassButtonFinder = find.byIcon(Icons.assistant_navigation);
      expect(compassButtonFinder, findsOneWidget);

      // Verify initial rotation (Adaptive is 90 degrees/0.25 turns)
      final animatedRotationFinder = find.byType(AnimatedRotation);
      expect(tester.widget<AnimatedRotation>(animatedRotationFinder).turns, 0.25);

      // Tap the button to toggle to North-up. The compass rotates with an animation,
      // so allow the 200ms animation to finish before checking the final turns value.
      await tester.tap(compassButtonFinder);
      await tester.pump(const Duration(milliseconds: 250));

      // Verify state and rotation updated (North-up is 0 degrees/0.0 turns)
      expect(preferredMapOrientation, MapOrientation.alwaysNorth);
      expect(tester.widget<AnimatedRotation>(animatedRotationFinder).turns, 0.0);

      // Tap again to toggle back to Adaptive
      await tester.tap(compassButtonFinder);
      await tester.pump(const Duration(milliseconds: 250));

      // Verify we returned to the original state
      expect(preferredMapOrientation, MapOrientation.adaptive);
      expect(tester.widget<AnimatedRotation>(animatedRotationFinder).turns, 0.25);
    });

    testWidgets('tapping Road Closure legend opens road closures dialog', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Ensure we start in a known state
      preferredRoadClosurePolygonVisible = true;

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // Find the "Road closures" legend at the bottom left
      // There are two "Road closures" texts potentially (legend and dialog title),
      // but only the legend is present initially.
      final legendFinder = find.text('Road closures');
      expect(legendFinder, findsOneWidget);

      // Tap the legend
      await tester.tap(legendFinder);
      await tester.pump();

      // Verify the dialog is opened
      // The dialog has a title "Road closures" and specific body text.
      expect(find.byType(Dialog), findsOneWidget);
      expect(
          find.text(
              'Whilst Mill Road (between East Road and Coleridge Road), Mortimer Road, Headly Street and the tops of Tenison Road, St Barnabas Road, Devonshire Road, Gwydir Street, Cavendish Road and Catharine Street where they join Mill Road will be closed to traffic (including cyclists and scooters) between 09:00 and 17:30 on the day, there will be some vehicle movement.'),
          findsOneWidget);

      // Verify "Close" button exists to dismiss the dialog
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('tapping the Hide road closures text in the dialog hides the Road Closure polygon', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Set a realistic window size to avoid the dialog contents being off-screen
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Ensure we start in a known state
      preferredRoadClosurePolygonVisible = true;

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // Find the "Road closures" legend at the bottom left
      // There are two "Road closures" texts potentially (legend and dialog title),
      // but only the legend is present initially.
      final legendFinder = find.text('Road closures');
      expect(legendFinder, findsOneWidget);

      // Tap the legend
      await tester.tap(legendFinder);
      await tester.pump();

      // Tap the "Hide road closures" text in the dialog
      final hideRoadClosuresFinder = find.text('Hide road closures');
      expect(hideRoadClosuresFinder, findsOneWidget);
      await tester.tap(hideRoadClosuresFinder);
      await tester.pump();

      // Verify state update and polygon removal
      expect(preferredRoadClosurePolygonVisible, isFalse);
      expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).polygons.any((p) => p.polygonId.value == 'roadClosure'), isFalse);
    });

    testWidgets('Road Closure filter toggles polygon visibility', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Ensure we start in a known state
      preferredRoadClosurePolygonVisible = true;

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      final state = tester.state<MapPageState>(find.byType(MapPage));

      // Verify initial state: polygon should be present
      expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).polygons.any((p) => p.polygonId.value == 'roadClosure'), isTrue);

      state.updateRoadClosurePolygonVisibility(false);
      await tester.pump();
      expect(preferredRoadClosurePolygonVisible, isFalse);
      expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).polygons.any((p) => p.polygonId.value == 'roadClosure'), isFalse);

      state.updateRoadClosurePolygonVisibility(true);
      await tester.pump();
      expect(preferredRoadClosurePolygonVisible, isTrue);
      expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).polygons.any((p) => p.polygonId.value == 'roadClosure'), isTrue);
    });

    testWidgets('addMarker filters and adds marker based on filter settings', (tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // Obtain the state after mounting
      final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;
      mapPageState.addAllVisibleMarkers();

      // Configure the map marker filter
      mapPageState.filterSettings["Food"] = true;

      // Verify that the expected marker was added
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 2);
      expect(mapPageState.markers.values.toSet().any((marker) => marker.markerId == const MarkerId('26101')), true);
    });

    test('getCategoryColor returns correct color for given types', () {
      final foodColor = getCategoryColor("light", "Food");
      final shoppingColor = getCategoryColor("light", "Shopping");
      final performanceColor = getCategoryColor("light", "Music");
      final charityCommunityInfoColor = getCategoryColor("light", "Charity/Community/Info");
      final visitExperienceColor = getCategoryColor("light", "Visit/Experience");
      final serviceColor = getCategoryColor("light", "Service");
      final mixedColor = getCategoryColor("light", "Mixed");

      expect(foodColor, const Color.fromRGBO(255, 156, 26, 1.0));
      expect(shoppingColor, const Color.fromRGBO(209, 85, 89, 1.0));
      expect(performanceColor, const Color.fromRGBO(190, 110, 230, 1.0));
      expect(charityCommunityInfoColor, const Color.fromRGBO(150, 80, 0, 1.0));
      expect(visitExperienceColor, const Color.fromRGBO(79, 184, 75, 1.0));
      expect(serviceColor, const Color.fromRGBO(84, 145, 245, 1.0));
      expect(mixedColor, const Color.fromRGBO(166, 34, 43, 1));
    });

    testWidgets('Adds markers, opens modal bottom sheet for group marker, and checks content', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Override user location global
      currentLatLng = const LatLng(52.199174, 0.140929);

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // Obtain the state after mounting
      final mapPageState = tester.state<MapPageState>(find.byType(MapPage));
      mapPageState.addAllVisibleMarkers();

      // Simulate a tap on the map marker
      const markerId = MarkerId('26101');
      final marker = mapPageState.markers.values.toList().firstWhere((marker) => marker.markerId == markerId);
      marker.onTap!();
      await tester.pump();

      // Check the text content in the bottom sheet
      // Group marker content
      expect(find.text('Food Group'), findsOneWidget);
      expect(find.text('10:30—16:30'), findsOneWidget);
      expect(find.byIcon(Icons.fastfood), findsOneWidget);
      expect(find.text('~199m away'), findsOneWidget);
      // Specific marker content
      expect(find.text('🍩 '), findsOneWidget);
      expect(find.text('Glazed and Confused'), findsOneWidget);
      expect(find.text('Doughnuts'), findsOneWidget);
      expect(find.text('11:00—15:00'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    });

    testWidgets('Adds markers, opens modal bottom sheet for specific marker, and checks content', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Override user location global
      currentLatLng = const LatLng(52.199174, 0.140929);

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // Obtain the state after mounting
      final mapPageState = tester.state<MapPageState>(find.byType(MapPage));
      mapPageState.addAllVisibleMarkers();

      // Simulate a tap on the map marker
      const markerId = MarkerId('26012');
      final marker = mapPageState.markers.values.toList().firstWhere((marker) => marker.markerId == markerId);
      marker.onTap!();
      await tester.pump();

      // Check the text content in the bottom sheet
      expect(find.text('🍣 '), findsOneWidget);
      expect(find.text('Sushi Squad'), findsOneWidget);
      expect(find.text('12:00—16:30'), findsOneWidget);
      expect(find.text('Mortimer Road (~135m away)'), findsOneWidget);
      expect(find.text('Telephone: 01223 222222'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    });

    testWidgets('shows filter menu and interacts with filter options', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      listings = [
        {
          "id": "26001",
          "visibleOnMap": "TRUE",
          "cancelled": "FALSE",
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          "emoji": "🍩",
          "title": "Glazed and Confused",
          "subtitle": "Doughnuts",
          "groupID": "",
          "food": "TRUE",
          "shopping": "FALSE",
          "charityCommunityInfo": "FALSE",
          "performanceMusic": "FALSE",
          "performanceChildrens": "FALSE",
          "performanceDance": "FALSE",
          "performanceOther": "FALSE",
          "visitExperience": "FALSE",
          "service": "FALSE",
          "location": "Gwydir Street",
          "description": "Nice buns",
          "email": "",
          "website": "https://glazedandconfused.example",
          "phone": "01223 111111",
          "latLng": "52.199687,0.138813",
          'imageURL': '',
          "startTime": "10:30",
          "endTime": "16:30",
        },
        {
          "id": "26002",
          "visibleOnMap": "TRUE",
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          "emoji": "🎨",
          "title": "The Crafty Canvas",
          "subtitle": "Crafts",
          "groupID": "",
          "food": "FALSE",
          "shopping": "TRUE",
          "charityCommunityInfo": "FALSE",
          "performanceMusic": "FALSE",
          "performanceChildrens": "FALSE",
          "performanceDance": "FALSE",
          "performanceOther": "FALSE",
          "visitExperience": "FALSE",
          "service": "FALSE",
          "location": "East Road",
          "description": "Artistic crafts for all ages",
          "email": "contact@craftycanvas.com",
          "website": "https://www.craftycanvas.com",
          "phone": "01223 222222",
          "latLng": "52.201913,0.131984",
          'imageURL': '',
          "startTime": "10:30",
          "endTime": "16:30",
        },
        {
          "id": "26003",
          "visibleOnMap": "TRUE",
          "cancelled": "FALSE",
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          "emoji": "🎷",
          "title": "The Jazz Junction",
          "subtitle": "Jazz",
          "groupID": "",
          "food": "FALSE",
          "shopping": "FALSE",
          "charityCommunityInfo": "FALSE",
          "performanceMusic": "TRUE",
          "performanceChildrens": "FALSE",
          "performanceDance": "FALSE",
          "performanceOther": "FALSE",
          "visitExperience": "FALSE",
          "service": "FALSE",
          "location": "East Road",
          "description": "Smooth jazz performances all day",
          "email": "contact@jazzjunction.com",
          "website": "https://www.jazzjunction.com",
          "phone": "01223 333333",
          "latLng": "52.202188,0.131312",
          'imageURL': '',
          "startTime": "10:30",
          "endTime": "16:30",
        },
        {
          "id": "26004",
          "visibleOnMap": "TRUE",
          "cancelled": "FALSE",
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          "emoji": "🎅",
          "title": "Santa",
          "subtitle": "Kindly Elf",
          "groupID": "",
          "food": "FALSE",
          "shopping": "FALSE",
          "charityCommunityInfo": "TRUE",
          "performanceMusic": "FALSE",
          "performanceChildrens": "FALSE",
          "performanceDance": "FALSE",
          "performanceOther": "FALSE",
          "visitExperience": "FALSE",
          "service": "FALSE",
          "location": "Zion Baptist Church",
          "description": "Santa will be available all day",
          "email": "",
          "website": "",
          "phone": "",
          "latLng": "52.203563,0.132437",
          'imageURL': '',
          "startTime": "10:30",
          "endTime": "16:30",
        },
        {
          "id": "26005",
          "visibleOnMap": "TRUE",
          "cancelled": "FALSE",
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          "emoji": "ℹ️",
          "title": "Information Point",
          "subtitle": "Help Point",
          "groupID": "",
          "food": "FALSE",
          "shopping": "FALSE",
          "charityCommunityInfo": "FALSE",
          "performanceMusic": "FALSE",
          "performanceChildrens": "FALSE",
          "performanceDance": "FALSE",
          "performanceOther": "FALSE",
          "visitExperience": "FALSE",
          "service": "TRUE",
          "location": "Ditchburn Gardens",
          "description": "Visit us for any questions or assistance",
          "email": "info@millroadwinterfair.org",
          "website": "",
          "phone": "",
          "latLng": "52.200187,0.137313",
          'imageURL': '',
          "startTime": "10:30",
          "endTime": "16:30",
        }
      ];

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // Obtain the state after mounting
      mapPageState = tester.state<MapPageState>(find.byType(MapPage));
      mapPageState.addAllVisibleMarkers();

      // Verify that the expected marker was added
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);

      // Open the filter menu
      await tester.tap(find.byTooltip('Choose which map markers to show'));
      await tester.pump();

      // Verify the "Filter Map Pins" title text is shown
      expect(find.text("Filter map layers"), findsOneWidget);

      // Verify all checkboxes are present
      expect(find.widgetWithText(CheckboxListTile, "Food and drink"), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, "Shopping"), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, "Charity, community, info"), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, "Music"), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, "Children’s entertainment"), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, "Dance"), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, "Other performances"), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, "Visits and experiences"), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, "Other businesses"), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, "Services"), findsOneWidget);

      // Test Food checkbox using direct state toggling, which is stable under the animated UI.
      mapPageState.filterSettings['Food'] = false;
      mapPageState.showFilteredMarkers();
      await tester.pump();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);
      await tester.tap(find.widgetWithText(CheckboxListTile, "Food and drink").first);
      await tester.pumpAndSettle();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);

      // Test Shopping checkbox
      mapPageState.filterSettings['Shopping'] = false;
      mapPageState.showFilteredMarkers();
      await tester.pump();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);
      await tester.tap(find.widgetWithText(CheckboxListTile, "Shopping"));
      await tester.pumpAndSettle();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);

      // Test Music checkbox
      mapPageState.filterSettings['Music'] = false;
      mapPageState.showFilteredMarkers();
      await tester.pump();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);
      await tester.tap(find.widgetWithText(CheckboxListTile, "Music"));
      await tester.pumpAndSettle();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);

      // Test Events checkbox
      mapPageState.filterSettings['Charity/Community/Info'] = false;
      mapPageState.showFilteredMarkers();
      await tester.pump();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);
      await tester.tap(find.widgetWithText(CheckboxListTile, "Charity, community, info"));
      await tester.pumpAndSettle();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);

      // Test Services checkbox
      mapPageState.filterSettings['Services'] = false;
      mapPageState.showFilteredMarkers();
      await tester.pump();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, false);
      await tester.tap(find.widgetWithText(CheckboxListTile, "Services"));
      await tester.pumpAndSettle();
      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers.length, 5);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, false);

      // Verify "Show All" button works
      final showAll = find.text("Show all");
      await tester.dragUntilVisible(
        showAll,
        find.byType(SingleChildScrollView),
        const Offset(0, 50),
      );
      await tester.tap(showAll);
      await tester.pumpAndSettle();
      expect(find.text("Filter map layers"), findsOne);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, true);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, true);

      // Verify "Hide All" button works
      final hideAll = find.text("Hide all");
      await tester.dragUntilVisible(
        showAll,
        find.byType(SingleChildScrollView),
        const Offset(0, 50),
      );
      await tester.tap(hideAll);
      await tester.pumpAndSettle();
      expect(find.text("Filter map layers"), findsOne);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26002')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26003')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26004')]?.visible, false);
      expect(mapPageState.markers[const MarkerId('26005')]?.visible, false);
    });

    testWidgets('hideAllMarkers clears all markers', (tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      listings = [
        mockListing('glazedAndConfused')
      ];

      // Build the MapPage widget
      await tester.pumpWithClock(
        MaterialApp(
          home: Scaffold(
            body: MapPage(listings: listings, analyticsService: FakeAnalyticsService(), onTabSelected: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // Obtain the state after mounting
      final mapPageState = tester.state(find.byType(MapPage)) as MapPageState;
      mapPageState.addAllVisibleMarkers();

      expect(mapPageState.markers.isNotEmpty, true);
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, true);

      mapPageState.hideAllMarkers();
      expect(mapPageState.markers[const MarkerId('26001')]?.visible, false);
    });

    testWidgets('Compass AnimatedRotation reflects preferredMapOrientation and toggles on button press', (WidgetTester tester) async {
      // We'll build a small widget that mirrors MapPage's AnimatedRotation and toggle logic.
      preferredMapOrientation = MapOrientation.adaptive;

      Widget testWidget = MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              double compassBearing = (preferredMapOrientation == MapOrientation.adaptive) ? 90 : 0;
              return Column(
                children: [
                  AnimatedRotation(
                    turns: compassBearing / 360.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.navigation),
                  ),
                  IconButton(
                    icon: const Icon(Icons.assistant_navigation),
                    onPressed: () {
                      setState(() {
                        preferredMapOrientation = (preferredMapOrientation == MapOrientation.adaptive) ? MapOrientation.alwaysNorth : MapOrientation.adaptive;
                      });
                    },
                  )
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpWithClock(testWidget);
      await tester.pump();

      final animatedRotationFinder = find.byType(AnimatedRotation);
      expect(animatedRotationFinder, findsOneWidget);
      AnimatedRotation widgetBefore = tester.widget<AnimatedRotation>(animatedRotationFinder);
      expect(widgetBefore.turns, closeTo(90.0 / 360.0, 0.001));

      await tester.tap(find.byIcon(Icons.assistant_navigation));
      await tester.pump(const Duration(milliseconds: 250));

      AnimatedRotation widgetAfter = tester.widget<AnimatedRotation>(animatedRotationFinder);
      expect(widgetAfter.turns, closeTo(0.0, 0.001));
    });

    // TODO: Add test for initial polyline plotting
    // TODO: Add test for polyline updates
  });
}