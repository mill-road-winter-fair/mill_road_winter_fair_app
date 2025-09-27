import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

void main() {
  LatLng currentLatLng = const LatLng(52.199174, 0.140929);
  LatLng destinationLatLng = const LatLng(52.199687, 0.138813);
  int approximateDistanceMetres = asTheCrowFlies(currentLatLng, destinationLatLng);

  // Build widget tree
  Widget createWidgetUnderTest({
    required String title,
    required String categories,
    required String openingTimes,
    required String approxDistance,
    required String phoneNumber,
    required String website,
    required Function onGetDirections,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ListingInfoSheet(
          title: title,
          categories: categories,
          openingTimes: openingTimes,
          approxDistance: approxDistance,
          phoneNumber: phoneNumber,
          website: website,
          onGetDirections: onGetDirections,
        ),
      ),
    );
  }

  testWidgets('displays title, categories opening times and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      title: 'Glazed and Confused',
      categories: 'Food • Doughnuts',
      openingTimes: '10:30 - 16:30',
      approxDistance: convertDistanceUnits(approximateDistanceMetres, DistanceUnits.metric),
      phoneNumber: '01223 111111',
      website: 'https://www.glazedandconfused.com',
      onGetDirections: () {},
    ));

    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Food • Doughnuts'), findsOneWidget);
    expect(find.text('10:30 - 16:30'), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
  });

  testWidgets('displays title, categories opening times and directions button, but not website button', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      title: 'Glazed and Confused',
      categories: 'Food • Doughnuts',
      openingTimes: '10:30 - 16:30',
      approxDistance: convertDistanceUnits(approximateDistanceMetres, DistanceUnits.metric),
      phoneNumber: '01223 111111',
      website: '',
      onGetDirections: () {},
    ));

    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Food • Doughnuts'), findsOneWidget);
    expect(find.text('10:30 - 16:30'), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    expect(find.byIcon(Icons.public), findsNothing);
  });

  // TODO: Add test for tapping on phone numbers (will need to find a way of mocking launchUrl)
  // TODO: Add test for tapping on "Open Website" button (will need to find a way of mocking launchUrl)

  testWidgets('calls onGetDirections when Get Directions button is pressed', (WidgetTester tester) async {
    bool directionsCalled = false;

    await tester.pumpWidget(createWidgetUnderTest(
      title: 'Glazed and Confused',
      categories: 'Food • Doughnuts',
      openingTimes: '10:30 - 16:30',
      approxDistance: convertDistanceUnits(approximateDistanceMetres, DistanceUnits.metric),
      phoneNumber: '01223 111111',
      website: 'https://www.glazedandconfused.com',
      onGetDirections: () {
        directionsCalled = true;
      },
    ));

    final getDirectionsButton = find.text('Get Directions');
    expect(getDirectionsButton, findsOneWidget);

    await tester.tap(getDirectionsButton);
    await tester.pumpAndSettle();

    // Check if the onGetDirections callback was triggered
    expect(directionsCalled, true);
  });
}
