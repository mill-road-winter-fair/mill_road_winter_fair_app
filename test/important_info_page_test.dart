import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750));
}

void main() {
  // Indicate tests are running
  onTest = true;

  setUpAll(() async {
    // Mock location services and permissions
    locationServicesEnabled = true;
    locationPermission = LocationPermission.always;

    // Load default settings
    await loadSettings();
  });

  group('ImportantInfoPage', () {
    testWidgets('displays expected headings and content', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ImportantInfoPage()));

      // Verify headings
      expect(find.text('Important information'), findsOneWidget);
      expect(find.text('Caution – vehicles!'), findsOneWidget);
      expect(find.text('First aid'), findsOneWidget);
      expect(find.text('Coming with children?'), findsOneWidget);
      expect(find.text('Road closure'), findsOneWidget);
      expect(find.text('Updates and contact'), findsOneWidget);
    });

    testWidgets('back button and back gesture return to the last selected HomePage tab', (WidgetTester tester) async {
      // Minimal listings so pages render correctly
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
          'groupParent': 'FALSE',
          'brickAndMortar': 'FALSE',
          'emoji': '🍩',
          'title': 'Glazed and Confused',
          'subtitle': 'Doughnuts',
          'groupID': '',
          'food': 'TRUE',
          'shopping': 'FALSE',
          'charityCommunityInfo': 'FALSE',
          'performance': 'FALSE',
          'visitExperience': 'FALSE',
          'service': 'FALSE',
          'location': 'Gwydir St Car Park',
          'description': 'Nice buns',
          'email': '',
          'website': 'https://www.glazedandconfused.com',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'imageURL': '',
          'startTime': '10:30',
          'endTime': '16:30',
        }
      ];

      await tester.pumpWidget(const MyApp());
      await settle(tester);

      final homePageState = tester.state(find.byType(HomePage)) as HomePageState;

      // Select the Listings tab before opening Important information.
      await tester.tap(find.text('Listings'));
      await settle(tester);
      expect(homePageState.index, 3);

      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
      await tester.tap(find.text('Important information'));
      await settle(tester);
      expect(find.byType(ImportantInfoPage), findsOneWidget);

      // The AppBar back button returns to the previously selected tab.
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.byType(ImportantInfoPage), findsNothing);
      expect(homePageState.index, 3);

      // Repeat from a different tab using the system back/back gesture.
      await tester.tap(find.text('Timetable'));
      await settle(tester);
      expect(homePageState.index, 2);

      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
      await tester.tap(find.text('Important information'));
      await settle(tester);
      expect(find.byType(ImportantInfoPage), findsOneWidget);

      await tester.pageBack();
      await settle(tester);
      expect(find.byType(ImportantInfoPage), findsNothing);
      expect(homePageState.index, 2);
    });

    testWidgets('email hyperlink opens the contact dialog', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ImportantInfoPage()));

      final emailParagraph = tester.widget<Text>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textSpan
                      ?.toPlainText()
                      .contains('Email addresses for the Fair') ==
                  true,
        ),
      );
      final paragraphSpan = emailParagraph.textSpan as TextSpan;
      final linkSpan = paragraphSpan.children!
          .whereType<TextSpan>()
          .singleWhere((span) => span.text == 'here');

      (linkSpan.recognizer as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('For general enquiries:'), findsOneWidget);
      expect(find.text('info@millroadwinterfair.org'), findsOneWidget);
      expect(find.text('volunteers@millroadwinterfair.org'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
