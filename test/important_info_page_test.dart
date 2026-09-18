import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class FakeUrlLauncher extends UrlLauncherPlatform {
  final List<String> checkedUrls = [];
  final List<String> launchedUrls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    checkedUrls.add(url);
    return true;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
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

  group('ImportantInfoPage', () {
    testWidgets('displays expected headings and content', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ImportantInfoPage(analyticsService: FakeAnalyticsService())));

      // Verify headings
      expect(find.text('Important information'), findsOneWidget);
      expect(find.text('Caution – vehicles!'), findsOneWidget);
      expect(find.text('First aid'), findsOneWidget);
      expect(find.text('Coming with children?'), findsOneWidget);
      expect(find.text('Road closure'), findsOneWidget);
      expect(find.text('Updates and contact'), findsOneWidget);
    });

    testWidgets('back button and back gesture return to the last selected HomePage tab', (WidgetTester tester) async {
      // Set firstExecution to false to simulate normal app launch
      firstExecution = false;

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

      await tester.pumpWidget(MyApp(
        firstExecution: false,
        analyticsService: FakeAnalyticsService(),
      ));
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
      await tester.pumpWidget(MaterialApp(
          home: ImportantInfoPage(
        analyticsService: FakeAnalyticsService(),
      )));

      final emailParagraph = tester.widget<Text>(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.textSpan?.toPlainText().contains('Email addresses for the Fair') == true,
        ),
      );
      final paragraphSpan = emailParagraph.textSpan as TextSpan;
      final linkSpan = paragraphSpan.children!.whereType<TextSpan>().singleWhere((span) => span.text == 'here');

      (linkSpan.recognizer as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('For general enquiries:'), findsOneWidget);
      expect(find.text('info@millroadwinterfair.org'), findsOneWidget);
      expect(find.text('volunteers@millroadwinterfair.org'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    group('external hyperlinks', () {
      final originalUrlLauncher = UrlLauncherPlatform.instance;
      late FakeUrlLauncher fakeUrlLauncher;

      setUp(() {
        fakeUrlLauncher = FakeUrlLauncher();
        UrlLauncherPlatform.instance = fakeUrlLauncher;
      });

      tearDown(() {
        UrlLauncherPlatform.instance = originalUrlLauncher;
      });

      Future<void> pumpPage(WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: ImportantInfoPage(
            analyticsService: FakeAnalyticsService(),
          ),
        ));
      }

      TextSpan findLinkSpan(
        WidgetTester tester, {
        required String paragraphText,
        required String linkText,
      }) {
        final paragraph = tester.widget<Text>(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.textSpan?.toPlainText().contains(paragraphText) == true,
          ),
        );
        final paragraphSpan = paragraph.textSpan as TextSpan;
        return paragraphSpan.children!.whereType<TextSpan>().singleWhere((span) => span.text == linkText);
      }

      testWidgets('website hyperlink launches the road closure notice', (WidgetTester tester) async {
        await pumpPage(tester);

        final linkSpan = findLinkSpan(
          tester,
          paragraphText: 'Road Closure Notice',
          linkText: 'www.millroadwinterfair.org',
        );

        (linkSpan.recognizer as TapGestureRecognizer).onTap!();
        await tester.pumpAndSettle();

        expect(
          fakeUrlLauncher.launchedUrls,
          ['https://www.millroadwinterfair.org/wp-content/uploads/2025/11/Road-Closure-Notice.pdf'],
        );
      });

      testWidgets('phone hyperlink launches the telephone dialler', (WidgetTester tester) async {
        await pumpPage(tester);

        final linkSpan = findLinkSpan(
          tester,
          paragraphText: 'On the day, you can also phone',
          linkText: '07303 142689',
        );

        (linkSpan.recognizer as TapGestureRecognizer).onTap!();
        await tester.pumpAndSettle();

        expect(fakeUrlLauncher.checkedUrls, ['tel:07303%20142689']);
        expect(fakeUrlLauncher.launchedUrls, ['tel:07303%20142689']);
      });
    });
  });
}
