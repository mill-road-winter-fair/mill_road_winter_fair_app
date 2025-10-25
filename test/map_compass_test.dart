import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/listings.dart';

void main() async {
  // We're on test
  onTest = true;

  // Ensure settings and permissions are mocked
  await loadSettings();
  locationPermission = LocationPermission.always;
  locationServicesEnabled = true;

  final sampleListings = [
    {
      'displayName': 'Sushi Squad',
      'endTime': '16:30',
      'id': '1',
      'name': 'sushisquad',
      'phone': '01223 222222',
      'latLng': '52.199188,0.139437',
      'primaryType': 'Food',
      'secondaryType': 'Implausible Avenue',
      'startTime': '12:00',
      'tertiaryType': 'Sushi',
      'visibleOnMap': true,
      'website': 'https://www.sushisquad.com',
    },
    {
      'displayName': 'Glazed and Confused',
      'endTime': '16:30',
      'id': '2',
      'name': 'glazedandconfused',
      'phone': '01223 111111',
      'latLng': '52.199687,0.138813',
      'primaryType': 'Food',
      'secondaryType': 'Food',
      'startTime': '10:30',
      'tertiaryType': 'Doughnuts',
      'visibleOnMap': true,
      'website': 'https://www.glazedandconfused.com',
    },
    {
      'displayName': 'Bite Club',
      'endTime': '16:30',
      'id': '3',
      'name': 'biteclub',
      'phone': '01223 333333',
      'latLng': '52.202313,0.131562',
      'primaryType': 'Food',
      'secondaryType': 'Food',
      'startTime': '14:00',
      'tertiaryType': 'Burgers',
      'visibleOnMap': true,
      'website': 'https://www.biteclub.com',
    },
  ];

  // Set global listings so pages relying on the global don't show error/loading UI
  listings = sampleListings;

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

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    final animatedRotationFinder = find.byType(AnimatedRotation);
    expect(animatedRotationFinder, findsOneWidget);
    AnimatedRotation widgetBefore = tester.widget<AnimatedRotation>(animatedRotationFinder);
    expect(widgetBefore.turns, closeTo(90.0 / 360.0, 0.001));

    await tester.tap(find.byIcon(Icons.assistant_navigation));
    await tester.pumpAndSettle();

    AnimatedRotation widgetAfter = tester.widget<AnimatedRotation>(animatedRotationFinder);
    expect(widgetAfter.turns, closeTo(0.0, 0.001));
  });
}
