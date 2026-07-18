import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
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

      expect(find.text(fairName), findsOneWidget);

      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('Performances'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Visits'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
    });

    testWidgets('Snowflake button in AppBar navigates to About the Fair page', (WidgetTester tester) async {
      // Provide a dummy listing to avoid triggering API fetch/retries and timers in MapPage
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
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

      // Provide initial mock values for shared preferences
      SharedPreferences.setMockInitialValues({});
      await loadSettings();

      // Pump MyApp which contains the AppBar with the snowflake button
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Find the snowflake button in the AppBar (it's an IconButton with an ImageIcon)
      final snowflakeButton = find.byWidgetPredicate(
            (widget) => widget is IconButton && widget.icon is ImageIcon,
      );
      expect(snowflakeButton, findsOneWidget);

      // Tap the snowflake button
      await tester.tap(snowflakeButton);
      await tester.pumpAndSettle();

      // Verify that AboutTheFairPage is now displayed
      expect(find.byType(AboutTheFairPage), findsOneWidget);
      expect(find.text('About Mill Road Winter Fair'), findsOneWidget);

      // Handle the 20s toast timer from ListingUpdateNotifier.maybeShowNotice (triggered in MapPage initState)
      await tester.pump(const Duration(seconds: 21));
    });

    testWidgets('drawer displays expected widgets', (WidgetTester tester) async {
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
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

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(DrawerHeader), findsOneWidget);
      expect(find.text(fairName), findsOneWidget);
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
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
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

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('About the Fair'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutTheFairPage), findsOneWidget);
    });

    testWidgets('navigates to ImportantInfoPage when Important information in drawer is tapped', (WidgetTester tester) async {
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
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

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Important information'));
      await tester.pumpAndSettle();

      expect(find.byType(ImportantInfoPage), findsOneWidget);
    });

    testWidgets('navigates to SettingsPage when Settings in drawer is tapped', (WidgetTester tester) async {
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
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

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('BottomNavigationBar updates currentIndex on tap', (WidgetTester tester) async {
      listings = [
        {
          'id': '1',
          'visibleOnMap': 'TRUE',
          'cancelled': 'FALSE',
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

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Obtain the state after mounting
      final homePageState = tester.state(find.byType(HomePage)) as HomePageState;
      expect(homePageState.index, 1);

      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 2);

      await tester.tap(find.text('Performances'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 3);

      await tester.tap(find.text('Community'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 4);

      await tester.tap(find.text('Visits'));
      await tester.pumpAndSettle();

      expect(homePageState.index, 5);

      await tester.tap(find.text('Services'));
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
