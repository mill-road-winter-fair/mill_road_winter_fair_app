import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class FakeUrlLauncher extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}

class RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

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

  group('AboutTheFairPage', () {
    Future<void> pumpAboutPage(
      WidgetTester tester, {
      NavigatorObserver? navigatorObserver,
    }) async {
      listings = [];
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: AboutTheFairPage(analyticsService: FakeAnalyticsService()),
          navigatorObservers: [
            if (navigatorObserver != null) navigatorObserver,
          ],
        ),
      );
      await tester.pump();
    }

    TapGestureRecognizer linkRecognizer(
      WidgetTester tester, {
      required String paragraphStartsWith,
      required String linkText,
    }) {
      final paragraph = tester.widget<Text>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textSpan?.toPlainText().startsWith(paragraphStartsWith) ==
                  true,
        ),
      );
      final paragraphSpan = paragraph.textSpan as TextSpan;
      final linkSpan = paragraphSpan.children!
          .whereType<TextSpan>()
          .singleWhere((span) => span.text == linkText);

      return linkSpan.recognizer as TapGestureRecognizer;
    }

    testWidgets('key event hyperlinks start navigation to their locations', (
      tester,
    ) async {
      final navigatorObserver = RecordingNavigatorObserver();
      final destinations = [
        (
          paragraph: 'Fire engine pull',
          link: 'East Road',
          id: '$aSimpleMarkerId Visit/Experience',
          position: const LatLng(52.202488, 0.131207),
        ),
        (
          paragraph: 'Fire engine pull',
          link: 'the bridge',
          id: '$aSimpleMarkerId Visit/Experience',
          position: const LatLng(52.198682, 0.141051),
        ),
        (
          paragraph: 'Opening ceremony',
          link: 'Ditchburn Gardens',
          id: '$aSimpleMarkerId Performance',
          position: const LatLng(52.200389, 0.136465),
        ),
        (
          paragraph: 'Parade',
          link: 'Salisbury Club',
          id: '$aSimpleMarkerId Performance',
          position: const LatLng(52.1970778, 0.1472252),
        ),
        (
          paragraph: 'Parade',
          link: 'Petersfield',
          id: '$aSimpleMarkerId Performance',
          position: const LatLng(52.202858, 0.132253),
        ),
        (
          paragraph: 'Final parade',
          link: 'Gwydir Street',
          id: '$aSimpleMarkerId Performance',
          position: const LatLng(52.199627, 0.138407),
        ),
        (
          paragraph: 'Final parade',
          link: 'Petersfield',
          id: '$aSimpleMarkerId Performance',
          position: const LatLng(52.202858, 0.132253),
        ),
      ];

      for (final destination in destinations) {
        await pumpAboutPage(tester, navigatorObserver: navigatorObserver);
        navigatorObserver.pushedRoutes.clear();

        linkRecognizer(
          tester,
          paragraphStartsWith: destination.paragraph,
          linkText: destination.link,
        ).onTap!();

        final route = navigatorObserver.pushedRoutes.single;
        expect(route, isA<MaterialPageRoute<dynamic>>());
        final mapPage = (route as MaterialPageRoute<dynamic>).builder(
          tester.element(find.byType(AboutTheFairPage)),
        ) as MapPage;
        expect(mapPage.destinationId, destination.id, reason: destination.link);
        expect(
          mapPage.destinationLatLng,
          destination.position,
          reason: destination.link,
        );
      }
    });

    testWidgets('sponsor hyperlinks launch the sponsor websites', (
      tester,
    ) async {
      final originalUrlLauncher = UrlLauncherPlatform.instance;
      final fakeUrlLauncher = FakeUrlLauncher();
      UrlLauncherPlatform.instance = fakeUrlLauncher;
      addTearDown(() => UrlLauncherPlatform.instance = originalUrlLauncher);

      const sponsorUrls = {
        'Bush & Co Sales and Lettings': 'https://bushandco.co.uk/',
        'Al-Amin': 'https://www.alamin.co.uk/',
        'Anglia Ruskin University': 'https://www.aru.ac.uk/',
        'Hughes Hall': 'https://www.hughes.cam.ac.uk/',
        'Love Mill Road': 'https://www.lovemillroad.org.uk/',
        'Regal Star Catering': 'https://www.lamaisondusteak.co.uk/',
        'Taank Optometrists': 'https://taank.co.uk/',
      };

      await pumpAboutPage(tester);

      for (final sponsor in sponsorUrls.entries) {
        linkRecognizer(
          tester,
          paragraphStartsWith: 'We are grateful for the generous support of',
          linkText: sponsor.key,
        ).onTap!();
        await tester.pump();
      }

      expect(fakeUrlLauncher.launchedUrls, sponsorUrls.values.toList());
    });

    testWidgets(
      'back button and back gesture return to the last selected HomePage tab',
      (WidgetTester tester) async {
        // Set firstExecution to false to simulate normal app launch
        firstExecution = false;

        // Minimal listings so pages render correctly
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
            'performanceMusic': 'FALSE',
            'performanceChildrens': 'FALSE',
            'performanceDance': 'FALSE',
            'performanceOther': 'FALSE',
            'visitExperience': 'FALSE',
            'service': 'FALSE',
            'business': 'FALSE',
            'location': 'Gwydir St Car Park',
            'description': 'Nice buns',
            'email': '',
            'website': 'https://www.glazedandconfused.com',
            'phone': '01223 111111',
            'latLng': '52.199687,0.138813',
            'imageURL': '',
            'startTime': '10:30',
            'endTime': '16:30',
          },
        ];

        await tester.pumpWidget(
          MyApp(
            firstExecution: false,
            analyticsService: FakeAnalyticsService(),
          ),
        );
        await settle(tester);

        // Obtain the HomePage state
        final homePageState =
            tester.state(find.byType(HomePage)) as HomePageState;

        // 1) Select Food tab (index 1)
        await tester.tap(find.text('Listings'));
        await settle(tester);
        expect(homePageState.index, 3);

        // Open drawer and navigate to About the Fair
        await tester.tap(find.byIcon(Icons.menu));
        await settle(tester);
        await tester.tap(find.text('About the Fair'));
        await settle(tester);

        expect(find.byType(AboutTheFairPage), findsOneWidget);

        // Tap the AppBar back button (leading) and verify we return to the Listings tab
        await tester.tap(find.byTooltip('Back'));
        await settle(tester);
        expect(homePageState.index, 3);

        // 2) Select Stalls tab (index 2)
        await tester.tap(find.text('Listings'));
        await settle(tester);
        expect(homePageState.index, 3);

        // Open drawer and navigate to About the Fair again
        await tester.tap(find.byIcon(Icons.menu));
        await settle(tester);
        await tester.tap(find.text('About the Fair'));
        await settle(tester);
        expect(find.byType(AboutTheFairPage), findsOneWidget);

        // Simulate system back / back gesture and verify we return to the Stalls tab
        await tester.pageBack();
        await settle(tester);
        expect(homePageState.index, 3);
      },
    );
  });
}
