import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/main.dart';

void main() {
  // We're on test
  onTest = true;

  setUpAll(() async {
    // Mock location services and permissions
    locationServicesEnabled = true;
    locationPermission = LocationPermission.always;

    // Mock user settings
    await loadSettings();
  });

  group('HomePage', () {
    testWidgets('displays correct title, BottomNavigationBar and buttons', (WidgetTester tester) async {
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      await tester.pumpWidget(const MyApp());

      expect(find.text('Mill Road Winter Fair 2025'), findsOneWidget);

      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Stalls'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Places'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('drawer displays expected widgets', (WidgetTester tester) async {
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(DrawerHeader), findsOneWidget);
      expect(find.text('Mill Road Winter Fair 2025'), findsOneWidget);
      expect(find.text('About the Fair'), findsOneWidget);
      expect(find.text('Important information'), findsOneWidget);
      expect(find.text('Visit our website'), findsOneWidget);
      expect(find.text('Contact us'), findsOneWidget);
      expect(find.byType(IconButton), findsExactly(6));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('App guide'), findsOneWidget);
      expect(find.text('About the app'), findsOneWidget);
    });

    testWidgets('navigates to AboutTheFairPage when About the Fair in drawer is tapped', (WidgetTester tester) async {
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('About the Fair'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutTheFairPage), findsOneWidget);
    });

    testWidgets('navigates to ImportantInfoPage when Important information in drawer is tapped', (WidgetTester tester) async {
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Important information'));
      await tester.pumpAndSettle();

      expect(find.byType(ImportantInfoPage), findsOneWidget);
    });

    testWidgets('navigates to SettingsPage when Settings in drawer is tapped', (WidgetTester tester) async {
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('BottomNavigationBar updates currentIndex on tap', (WidgetTester tester) async {
      listings = [
        {
          'displayName': 'Glazed and Confused',
          'endTime': '16:30',
          'id': '1',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'latLng': '52.199687,0.138813',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'website': 'https://www.glazedandconfused.com',
        }
      ];

      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Obtain the state after mounting
      final homePageState = tester.state(find.byType(HomePage)) as HomePageState;
      expect(homePageState.index, 1);

      await tester.tap(find.text('Stalls'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 2);

      await tester.tap(find.text('Music'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 3);

      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 4);

      await tester.tap(find.text('Places'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 5);

      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 6);

      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 0);
    });

    testWidgets('emailDetailsDialog shows emails and close button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      // show the dialog
      showDialog(context: tester.element(find.byType(SizedBox)), builder: (context) => contactUsDialog(context));
      await tester.pumpAndSettle();

      // Check for some known email addresses
      expect(find.text('info@millroadwinterfair.org'), findsOneWidget);
      expect(find.text('volunteers@millroadwinterfair.org'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Tap Close button and verify dialog is dismissed
      final close = find.text("Close");
      await tester.dragUntilVisible(
        close,
        find.byType(SingleChildScrollView),
        const Offset(0, 50),
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('info@millroadwinterfair.org'), findsNothing);
    });
  });
}
