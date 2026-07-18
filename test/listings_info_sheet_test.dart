import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/globals.dart';

void main() {
  LatLng currentLatLng = const LatLng(52.199174, 0.140929);
  LatLng destinationLatLng = const LatLng(52.199687, 0.138813);
  int approximateDistanceMetres = asTheCrowFlies(currentLatLng, destinationLatLng);

  // Build widget tree
  Widget createWidgetUnderTest({
    required bool cancelled,
    required String emoji,
    required String title,
    required String subtitle,
    required String location,
    required String description,
    required String email,
    required String website,
    required String phoneNumber,
    required String startTime,
    required String endTime,
    required String approxDistance,
    required bool detailsVisible,
    required bool listingFavourited,
    required Function onGetDirections,
    VoidCallback? onDetailsTapped,
    VoidCallback? onFavouriteTapped,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SpecificListingInfoSheet(
          cancelled: cancelled,
          emoji: emoji,
          title: title,
          subtitle: subtitle,
          location: location,
          description: description,
          email: email,
          website: website,
          phoneNumber: phoneNumber,
          startTime: startTime,
          endTime: endTime,
          approxDistance: approxDistance,
          detailsVisible: detailsVisible,
          onGetDirections: onGetDirections,
          listingFavourited: listingFavourited,
          onDetailsTapped: onDetailsTapped,
          onFavouriteTapped: onFavouriteTapped,
        ),
      ),
    );
  }

  group('ListingsInfoSheet', () {
    testWidgets('displays title, categories opening times and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        cancelled: false,
        emoji: '🍩',
        title: 'Glazed and Confused',
        subtitle: 'Food • Doughnuts',
        location: 'Gwydir St Car Park',
        description: 'Nice buns',
        email: 'sales@glazedandconfused.com',
        website: 'https://www.glazedandconfused.com',
        phoneNumber: '01223 111111',
        startTime: '10:30',
        endTime: '16:30',
        approxDistance: convertDistanceUnits(approximateDistanceMetres, DistanceUnits.metric),
        detailsVisible: true,
        onGetDirections: () {},
        listingFavourited: false,
      ));

      expect(find.text('🍩 Glazed and Confused'), findsOneWidget);
      expect(find.text('Food • Doughnuts'), findsOneWidget);
      expect(find.text('10:30—16:30'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets('displays title, categories opening times and directions button, but not website button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        cancelled: false,
        emoji: '🍩',
        title: 'Glazed and Confused',
        subtitle: 'Food • Doughnuts',
        location: 'Gwydir St Car Park',
        description: 'Nice buns',
        email: 'sales@glazedandconfused.com',
        website: '',
        phoneNumber: '01223 111111',
        startTime: '10:30',
        endTime: '16:30',
        approxDistance: convertDistanceUnits(approximateDistanceMetres, DistanceUnits.metric),
        detailsVisible: true,
        onGetDirections: () {},
        listingFavourited: false,
      ));

      expect(find.text('🍩 Glazed and Confused'), findsOneWidget);
      expect(find.text('Food • Doughnuts'), findsOneWidget);
      expect(find.text('10:30—16:30'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
      expect(find.byIcon(Icons.public), findsNothing);
    });

    // TODO: Add test for tapping on phone numbers (will need to find a way of mocking launchUrl)
    // TODO: Add test for tapping on "Open Website" button (will need to find a way of mocking launchUrl)

    testWidgets('calls onFavouriteTapped when heart button is pressed', (WidgetTester tester) async {
      bool favouriteCalled = false;

      await tester.pumpWidget(createWidgetUnderTest(
        cancelled: false,
        emoji: '🍩',
        title: 'Glazed and Confused',
        location: 'Gwydir St Car Park',
        subtitle: 'Food • Doughnuts',
        startTime: '10:30',
        endTime: '16:30',
        approxDistance: convertDistanceUnits(approximateDistanceMetres, DistanceUnits.metric),
        phoneNumber: '01223 111111',
        website: 'https://www.glazedandconfused.com',
        email: 'sales@glazedandconfused.com',
        description: 'Nice buns',
        detailsVisible: false,
        onGetDirections: () {},
        listingFavourited: false,
        onFavouriteTapped: () {
          favouriteCalled = true;
        },
      ));

      // Find the heart icon button. It's an IconButton containing a FaIcon.
      final heartButton = find.byType(IconButton).first;
      expect(heartButton, findsOneWidget);

      await tester.tap(heartButton);
      await tester.pumpAndSettle();

      // Check if the onFavouriteTapped callback was triggered
      expect(favouriteCalled, true);
    });

    testWidgets('tapping Details button toggles visibility of extra information', (WidgetTester tester) async {
      bool detailsToggled = false;

      // Initial state: details NOT visible
      await tester.pumpWidget(createWidgetUnderTest(
        cancelled: false,
        emoji: '🍩',
        title: 'Glazed and Confused',
        location: 'Gwydir St Car Park',
        subtitle: 'Food • Doughnuts',
        startTime: '10:30',
        endTime: '16:30',
        approxDistance: convertDistanceUnits(approximateDistanceMetres, DistanceUnits.metric),
        phoneNumber: '01223 111111',
        website: 'https://www.glazedandconfused.com',
        email: 'sales@glazedandconfused.com',
        description: 'Nice buns',
        detailsVisible: false,
        onGetDirections: () {},
        listingFavourited: false,
        onDetailsTapped: () {
          detailsToggled = true;
        },
      ));

      // Extra info should not be present
      expect(find.text('Nice buns'), findsNothing);

      // Tap the Details button
      final detailsButton = find.text('Details');
      expect(detailsButton, findsOneWidget);
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();

      // Verify the callback was triggered
      expect(detailsToggled, true);

      // Now pump with detailsVisible = true to simulate the state change
      await tester.pumpWidget(createWidgetUnderTest(
        cancelled: false,
        emoji: '🍩',
        title: 'Glazed and Confused',
        location: 'Gwydir St Car Park',
        subtitle: 'Food • Doughnuts',
        startTime: '10:30',
        endTime: '16:30',
        approxDistance: convertDistanceUnits(approximateDistanceMetres, DistanceUnits.metric),
        phoneNumber: '01223 111111',
        website: 'https://www.glazedandconfused.com',
        email: 'sales@glazedandconfused.com',
        description: 'Nice buns',
        detailsVisible: true,
        onGetDirections: () {},
        listingFavourited: false,
        onDetailsTapped: () {},
      ));

      // Extra info should now be present
      expect(find.text('Nice buns'), findsOneWidget);
      expect(find.text('Website: https://www.glazedandconfused.com'), findsOneWidget);
    });

    testWidgets('calls onGetDirections when Get Directions button is pressed', (WidgetTester tester) async {
      bool directionsCalled = false;

      await tester.pumpWidget(createWidgetUnderTest(
        cancelled: false,
        emoji: '🍩',
        title: 'Glazed and Confused',
        subtitle: 'Food • Doughnuts',
        location: 'Gwydir St Car Park',
        description: 'Nice buns',
        email: 'sales@glazedandconfused.com',
        website: 'https://www.glazedandconfused.com',
        phoneNumber: '01223 111111',
        startTime: '10:30',
        endTime: '16:30',
        approxDistance: convertDistanceUnits(approximateDistanceMetres, DistanceUnits.metric),
        detailsVisible: false,
        onGetDirections: () {
          directionsCalled = true;
        },
        listingFavourited: false,
      ));

      final getDirectionsButton = find.text('Directions');
      expect(getDirectionsButton, findsOneWidget);

      await tester.tap(getDirectionsButton);
      await tester.pumpAndSettle();

      // Check if the onGetDirections callback was triggered
      expect(directionsCalled, true);
    });

    testWidgets('formatted with line-through and red text when endTime has passed', (WidgetTester tester) async {
      // Note: This test assumes hasEventEnded returns true for the given endTime.
      // This will be true if the test is run after the fair date/time.
      await tester.pumpWidget(createWidgetUnderTest(
        cancelled: false,
        emoji: '🍩',
        title: 'Glazed and Confused',
        location: 'Gwydir St Car Park',
        subtitle: 'Food • Doughnuts',
        startTime: '09:00',
        endTime: '10:00', // Set to a time that has likely passed
        approxDistance: '100m',
        phoneNumber: '01223 111111',
        website: 'https://www.glazedandconfused.com',
        email: 'sales@glazedandconfused.com',
        description: 'Nice buns',
        detailsVisible: false,
        onGetDirections: () {},
        listingFavourited: false,
      ));

      final timeTextFinder = find.text('09:00—10:00');
      expect(timeTextFinder, findsOneWidget);

      final Text timeTextWidget = tester.widget(timeTextFinder);
      // If the event has ended, it should be red and have a line-through decoration
      if (hasEventEnded('10:00')) {
        expect(timeTextWidget.style?.color, Colors.red);
        expect(timeTextWidget.style?.decoration, TextDecoration.lineThrough);
      }
    });

    testWidgets('formatted with line-through and red text when listing is cancelled', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        cancelled: true,
        emoji: '🍩',
        title: 'Glazed and Confused',
        location: 'Gwydir St Car Park',
        subtitle: 'Food • Doughnuts',
        startTime: '10:30',
        endTime: '16:30',
        approxDistance: '100m',
        phoneNumber: '01223 111111',
        website: 'https://www.glazedandconfused.com',
        email: 'sales@glazedandconfused.com',
        description: 'Nice buns',
        detailsVisible: true,
        onGetDirections: () {},
        listingFavourited: false,
      ));

      // Title should have line-through
      final titleFinder = find.text('🍩 Glazed and Confused');
      expect(titleFinder, findsOneWidget);
      final Text titleWidget = tester.widget(titleFinder);
      expect(titleWidget.style?.decoration, TextDecoration.lineThrough);

      // Times should be replaced by CANCELLED and be red
      final cancelledTextFinder = find.text('CANCELLED');
      expect(cancelledTextFinder, findsWidgets); // Might be more than one if both subtitle and body use it
      final Text cancelledTextWidget = tester.widget(cancelledTextFinder.first);
      expect(cancelledTextWidget.style?.color, Colors.red);

      // Description should have prefix removed
      expect(find.text('Nice buns'), findsOneWidget);
    });
  });
}
