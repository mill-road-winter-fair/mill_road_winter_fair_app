import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheet.dart';

void main() {
  group('ListingInfoSheet Widget Tests', () {

    Widget createWidgetUnderTest({
      required String title,
      required String categories,
      required String openingTimes,
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
            phoneNumber: phoneNumber,
            website: website,
            onGetDirections: onGetDirections,
          ),
        ),
      );
    }

    testWidgets('displays title, categories, and opening times', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        title: 'Sample Place',
        categories: 'Food, Drinks',
        openingTimes: '09:00 - 17:00',
        phoneNumber: '',
        website: '',
        onGetDirections: () {},
      ));

      expect(find.text('Sample Place'), findsOneWidget);
      expect(find.text('Food, Drinks'), findsOneWidget);
      expect(find.text('09:00 - 17:00'), findsOneWidget);
    });

    //TODO: Add test for tapping on phone numbers
    //TODO: Add test for tapping on "Open Website" button

    testWidgets('calls onGetDirections when Get Directions button is pressed', (WidgetTester tester) async {
      bool directionsCalled = false;

      await tester.pumpWidget(createWidgetUnderTest(
        title: 'Sample Place',
        categories: 'Food, Drinks',
        openingTimes: '09:00 - 17:00',
        phoneNumber: '',
        website: '',
        onGetDirections: () {
          directionsCalled = true;
        },
      ));

      // Find the button using text alone since it's an ElevatedButton with an icon
      final getDirectionsButton = find.text('Get Directions');
      expect(getDirectionsButton, findsOneWidget);

      await tester.tap(getDirectionsButton);
      await tester.pumpAndSettle();

      // Check if the onGetDirections callback was triggered
      expect(directionsCalled, true);
    });
  });
}
