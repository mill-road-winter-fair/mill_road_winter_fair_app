// App imports
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/chooser_page.dart';
import 'package:mill_road_winter_fair_app/dependencies/launch_url_provider.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/welcome_screen.dart';

// Third-party imports
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Test helpers, fakes and mocks
import 'fakes/fake_url_launcher.dart';
import 'fakes/fixed_date_time_provider.dart';
import 'mocks/listings_mocks.dart';
import 'pump_with_clock.dart';

Finder findDrawerSocialButton(int index) {
  return find
      .descendant(
        of: find.byType(Drawer),
        matching: find.byType(IconButton),
      )
      .at(index);
}

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

  group('Chooser page entrance animation', () {
    test('hotspots reveal in sequence and reach full opacity by the end of the five second entrance', () {
      expect(hotspotEntranceOpacityForIndex(0, 0.0, totalHotspots: 8), 0.0);
      expect(hotspotEntranceOpacityForIndex(0, 0.09, totalHotspots: 8), 0.0);
      expect(hotspotEntranceOpacityForIndex(0, 0.2, totalHotspots: 8), greaterThan(0.0));
      expect(hotspotEntranceOpacityForIndex(1, 0.2, totalHotspots: 8), 0.0);
      expect(hotspotEntranceOpacityForIndex(1, 0.4, totalHotspots: 8), greaterThan(0.0));
      expect(hotspotEntranceOpacityForIndex(7, 1.0, totalHotspots: 8), 1.0);
    });
  });

  group('HomePage', () {
    for (final destination in ['Map', 'Timetable', 'Listings', 'map shortcut', 'timetable shortcut', 'listings shortcut']) {
      testWidgets('shows listings notice on first visit via $destination', (tester) async {
        SharedPreferences.setMockInitialValues({});
        listingUpdateNoticeEnabled = true;
        onTest = true;
        addTearDown(() => onTest = true);
        listings = [mockListing('glazedAndConfused')];
        await tester.pumpWithClock(
          MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()),
          dateTimeProvider: FixedDateTimeProvider(fairDate.subtract(const Duration(days: 1))),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.widget<MapPage>(find.byType(MapPage, skipOffstage: false)).allowListingsMayChangeNotice, isFalse);
        expect(find.text('Listings may change'), findsNothing);
        onTest = false;
        final home = tester.state<HomePageState>(find.byType(HomePage));
        home.setCurrentIndex(4);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Listings may change'), findsNothing);
        switch (destination) {
          case 'map shortcut':
            home.openMap(null);
          case 'timetable shortcut':
            home.openTimetable(false, null);
          case 'listings shortcut':
            home.openListings('all', null);
          default:
            await tester.tap(find.text(destination));
        }
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Listings may change'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        home.setCurrentIndex(0);
        home.setCurrentIndex(2);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Listings may change'), findsNothing);
      });
    }

    testWidgets('displays correct title, BottomNavigationBar and buttons', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      listings = [
        mockListing('glazedAndConfused')
      ];

      await tester.pumpWithClock(MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()));

      expect(find.textContaining('Welcome'), findsOneWidget);

      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Listings'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Favourites'), findsOneWidget);
    });

    testWidgets('drawer displays expected widgets', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      listings = [
        mockListing('glazedAndConfused')
      ];

      await tester.pumpWithClock(MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();

      expect(find.byType(DrawerHeader), findsOneWidget);
      expect(find.text('About the Fair'), findsOneWidget);
      expect(find.text('Important information'), findsOneWidget);
      expect(find.text('Visit our website'), findsOneWidget);
      expect(find.text('Contact us'), findsOneWidget);
      expect(find.text('Donate to the Fair'), findsOneWidget);
      expect(find.byType(IconButton), findsExactly(6));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('App guide'), findsOneWidget);
      expect(find.text('Share this app'), findsOneWidget);
      expect(find.text('About this app'), findsOneWidget);
    });

    group('drawer external links', () {
      late FakeUrlLauncher fakeUrlLauncher;

      setUp(() {
        fakeUrlLauncher = FakeUrlLauncher();
      });

      Future<void> openDrawer(WidgetTester tester) async {
        await tester.pumpWithClock(
          Provider<UrlLauncher>.value(
            value: fakeUrlLauncher,
            child: MaterialApp(
              home: FairScaffold(
                appBarTitle: 'Test',
                body: const SizedBox(),
                currentTab: 0,
                onTabSelected: (_) {}, analyticsService: FakeAnalyticsService(),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }

      Future<void> expectButtonLaunches(
        WidgetTester tester,
        Finder button,
        String expectedUrl,
      ) async {
        await tester.tap(button);
        await tester.pumpAndSettle();

        expect(fakeUrlLauncher.openedUris, [Uri.parse(expectedUrl)]);
      }

      testWidgets(
        'Visit our website button launches the Fair website',
        (tester) async {
          await openDrawer(tester);

          await expectButtonLaunches(
            tester,
            find.text('Visit our website'),
            'https://www.millroadwinterfair.org/',
          );
        },
      );

      testWidgets(
        'Facebook button launches the Fair Facebook page',
        (tester) async {
          await openDrawer(tester);

          await expectButtonLaunches(
            tester,
            findDrawerSocialButton(0),
            'https://www.facebook.com/MillRoadWinterFair/',
          );
        },
      );

      testWidgets('X button launches the Fair X page', (tester) async {
        await openDrawer(tester);

        await expectButtonLaunches(
          tester,
          findDrawerSocialButton(1),
          'https://x.com/millroadfair',
        );
      });

      testWidgets(
        'Instagram button launches the Fair Instagram page',
        (tester) async {
          await openDrawer(tester);

          await expectButtonLaunches(
            tester,
            findDrawerSocialButton(2),
            'https://www.instagram.com/millroadwinterfair/',
          );
        },
      );

      testWidgets('LinkedIn button launches the Fair LinkedIn page', (tester) async {
        await openDrawer(tester);

        await expectButtonLaunches(
          tester,
          findDrawerSocialButton(3),
          'https://www.linkedin.com/company/mill-road-winter-fair/',
        );
      });

      testWidgets('Flickr button launches the Fair Flickr page', (tester) async {
        await openDrawer(tester);

        await expectButtonLaunches(
          tester,
          findDrawerSocialButton(4),
          'https://www.flickr.com/people/millroadwinterfair/',
        );
      });
    });

    testWidgets('navigates to AboutTheFairPage when About the Fair in drawer is tapped', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      listings = [
        mockListing('glazedAndConfused')
      ];

      await tester.pumpWithClock(MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 500));
      final aboutFinder = find.text('About the Fair');
      expect(aboutFinder, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(aboutFinder);
      await tester.pumpAndSettle();
      expect(find.byType(AboutTheFairPage), findsOneWidget);
    });

    testWidgets('navigates to ImportantInfoPage when Important information in drawer is tapped', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      listings = [
        mockListing('glazedAndConfused')
      ];

      await tester.pumpWithClock(MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 500));
      final impInfoFinder = find.text('Important information');
      expect(impInfoFinder, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(impInfoFinder);
      await tester.pumpAndSettle();
      expect(find.byType(ImportantInfoPage), findsOneWidget);
    });

    testWidgets('navigates to SettingsPage when Settings in drawer is tapped', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      listings = [
        mockListing('glazedAndConfused')
      ];

      await tester.pumpWithClock(MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 500));
      final settingsFinder = find.text('Settings');
      expect(settingsFinder, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('navigates to WelcomeScreen/OnBoardingPage when App guide in drawer is tapped', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Set a realistic window size to avoid layout overflow in the test
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      listings = [
        mockListing('glazedAndConfused')
      ];

      await tester.pumpWithClock(MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 500));
      final appGuideFinder = find.text('App guide');
      expect(appGuideFinder, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(appGuideFinder);
      await tester.pumpAndSettle();

      // Verify that the WelcomeScreen is displayed
      expect(find.byType(WelcomeScreen), findsOneWidget);

      // Verify that OnBoardingPage is rendered within the WelcomeScreen
      expect(find.byType(OnBoardingPage), findsOneWidget);
    });

    testWidgets('show aboutDialog when About this app in drawer is tapped', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      listings = [
        mockListing('glazedAndConfused')
      ];

      await tester.pumpWithClock(MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 500));
      final aboutAppFinder = find.text('About this app');
      expect(aboutAppFinder, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(aboutAppFinder);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Android app by Alexander Berridge'), findsOneWidget);
      expect(find.text('iPhone version by Matt Whiting'), findsOneWidget);
    });

    testWidgets('BottomNavigationBar updates currentIndex on tap', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      listings = [
        mockListing('glazedAndConfused')
      ];

      await tester.pumpWithClock(MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()));

      await tester.pump(const Duration(milliseconds: 500));

      // Obtain the state after mounting
      final homePageState = tester.state(find.byType(HomePage)) as HomePageState;
      expect(homePageState.index, 0);

      await tester.tap(find.byIcon(Icons.map).first);
      await tester.pump();
      expect(homePageState.index, 1);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byIcon(Icons.ballot).first);
      await tester.pump();
      expect(homePageState.index, 3);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byIcon(Icons.watch_later).first);
      await tester.pump();
      expect(homePageState.index, 2);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite).first);
      await tester.pump();
      expect(homePageState.index, 4);
    });

    testWidgets('emailDetailsDialog shows emails and close button', (WidgetTester tester) async {
      await tester.pumpWithClock(const MaterialApp(home: Scaffold(body: SizedBox())));

      // show the dialog
      showDialog(context: tester.element(find.byType(SizedBox)), builder: (context) => contactUsDialog(context, analyticsService: FakeAnalyticsService()));
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

    testWidgets('Favourites button in NavBar navigates to Favourites page', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

      // Provide a dummy listing to avoid triggering API fetch/retries and timers in MapPage
      listings = [
        mockListing('glazedAndConfused')
      ];

      // Provide initial mock values for shared preferences
      SharedPreferences.setMockInitialValues({});
      await loadSettings();

      // Set the mock listing as a favourite before the widget is built
      favouriteListingKeys.value = {...favouriteListingKeys.value, '26001'};

      // Pump MyApp which contains the AppBar with the snowflake button
      await tester.pumpWithClock(MyApp(firstExecution: false, analyticsService: FakeAnalyticsService()));
      await tester.pump();

      // Tap the Favourites button the NavBar
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify that the favourites page is displayed
      expect(find.byType(FilteredListingsPage), findsOneWidget);
      expect(find.text('Glazed and Confused'), findsOneWidget);

      // Handle the 20s toast timer from ListingUpdateNotifier.maybeShowNotice (triggered in MapPage initState)
      await tester.pump(const Duration(seconds: 21));
    });
  });
}
