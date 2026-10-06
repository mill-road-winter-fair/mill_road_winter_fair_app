import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeScreen extends StatelessWidget {
  final AnalyticsService analyticsService;
  final VoidCallback? onFinished;
  const WelcomeScreen({super.key, required this.analyticsService, this.onFinished});

  @override
  Widget build(BuildContext context) {
    debugPrint('WelcomeScreen build() called');
    // The app guide shares the existing navigator and its route observer.
    if (Navigator.maybeOf(context) != null) {
      return OnBoardingPage(analyticsService: analyticsService);
    }
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    final bool isAuto = selectedThemeKey == 'auto';
    final ThemeMode resolvedThemeMode = isAuto
        ? ThemeMode.system
        : switch (selectedThemeKey) {
            'dark' => ThemeMode.dark,
            _ => ThemeMode.light,
          };
    mapStyle = getMapStyleForThemeKey(selectedThemeKey);

    return MaterialApp(
      title: 'Welcome screen',
      debugShowCheckedModeBanner: false,
      themeMode: resolvedThemeMode,
      theme: isAuto ? appThemes['light'] : appThemes[selectedThemeKey] ?? appThemes['light']!,
      darkTheme: isAuto ? appThemes['dark'] : appThemes['dark'],
      navigatorObservers: [routeObserver],
      home: OnBoardingPage(analyticsService: analyticsService, onFinished: onFinished),
    );
  }
}

class OnBoardingPage extends StatefulWidget {
  final AnalyticsService analyticsService;
  final VoidCallback? onFinished;
  const OnBoardingPage({super.key, required this.analyticsService, this.onFinished});

  @override
  OnBoardingPageState createState() => OnBoardingPageState();
}

class OnBoardingPageState extends State<OnBoardingPage> with RouteAware {
  final introKey = GlobalKey<IntroductionScreenState>();

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstExecution', false);
  }

  void _onIntroEnd(BuildContext context) {
    firstExecution = false;
    _saveSettings();
    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomePage(analyticsService: widget.analyticsService),
      ),
    );
  }

  @override
  void initState() {
    debugPrint('OnBoardingPageState initState() called');
    super.initState();
  }

  @override
  void dispose() {
    debugPrint('OnBoardingPageState dispose() called');
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routeObserver.subscribe(
      this,
      ModalRoute.of(context)!,
    );
  }

  @override
  void didPush() {
    widget.analyticsService.setCurrentScreen('WelcomePage');
  }

  @override
  void didPopNext() {
    widget.analyticsService.setCurrentScreen('WelcomePage');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('OnBoardingPageState build() called');
    final colourScheme = Theme.of(context).colorScheme;
    final bodyStyle = TextStyle(fontSize: 19, color: colourScheme.onSecondary, height: 1.4);
    final titleStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 21, fontWeight: FontWeight.bold, color: colourScheme.onSecondary);
    final pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: colourScheme.onSecondary),
      bodyTextStyle: TextStyle(fontSize: 19, color: colourScheme.onSecondary),
      bodyPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      titlePadding: const EdgeInsets.only(top: 12, bottom: 10),
      contentMargin: const EdgeInsets.symmetric(horizontal: 16),
      bodyFlex: 0,
      safeArea: 160,
      pageColor: colourScheme.secondary.withValues(alpha: 0.8),
    );
    Widget guideRow(Widget icon, Widget content) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 40, child: Center(child: icon)),
              const SizedBox(width: 8),
              Expanded(child: content),
            ],
          ),
        );

    Widget tip(IconData icon, String text) => guideRow(
          Icon(icon, size: 40, color: colourScheme.onSecondary),
          Text(text, style: bodyStyle),
        );

    Widget category(String key, String colourKey) => guideRow(
          Icon(subfilterCategoryLabels[key]!.iconData, size: 40, color: getCategoryColor(selectedThemeKey, colourKey)),
          Text(subfilterCategoryLabels[key]!.label, style: bodyStyle),
        );

    PageViewModel guidePage(String title, int artwork, List<Widget> children) {
      // The original non-scrolling page gives its body unbounded height. Reserve
      // room for its fitted title and controls before scaling the updated copy.
      final titlePainter = TextPainter(
        text: TextSpan(text: title, style: titleStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final titleWidth = MediaQuery.sizeOf(context).width - pageDecoration.contentMargin.horizontal;
      final titleScale = (titleWidth / titlePainter.width).clamp(0.0, 1.0);
      final bodyHeight = (MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).vertical -
              pageDecoration.safeArea -
              pageDecoration.titlePadding.vertical -
              pageDecoration.bodyPadding!.vertical -
              titlePainter.height * titleScale)
          .clamp(0.0, double.infinity);
      titlePainter.dispose();
      return PageViewModel(
        useScrollView: false,
        backgroundImage: 'assets/welcomeScreen/clareMcEwan_artwork0$artwork.jpg',
        titleWidget: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(title, style: titleStyle, textAlign: TextAlign.center),
        ),
        bodyWidget: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: bodyHeight.toDouble()),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              // Wrap the updated copy before fitting the whole page, as with the
              // original guide's manually wrapped rows.
              child: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
        ),
        decoration: pageDecoration,
      );
    }

    return IntroductionScreen(
      key: introKey,
      safeAreaList: [false, false, false, Platform.isAndroid && isNavBarVisible(context)],
      autoScrollDuration: onTest ? null : 150000,
      infiniteAutoScroll: onTest ? false : true,
      globalBackgroundColor: Theme.of(context).colorScheme.secondary,
      allowImplicitScrolling: true,
      globalFooter: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Take me straight to the app!',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)),
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              widget.analyticsService.logButtonTapped('skip_WelcomeScreen');
              _onIntroEnd(context);
            },
          ),
        ),
      ),
      pages: [
        guidePage('Welcome to the official\nMill Road Winter Fair app!', 0, [
          tip(Icons.home,
              'Using our new homepage, tap one of the colourful characters to explore food and drink, shopping, children’s activities and more.'),
          tip(Icons.music_note, 'Tap Music on the homepage to open the music timetable, or Nearby to find things around you on the map.'),
          tip(Icons.map, 'Use the buttons at the bottom of the screen to switch between the Homepage, Map, Timetable, Listings and your Favourites.'),
          tip(Icons.menu,
              'Use the menu in the top-right for important information, settings and to share this app. You can read this App Guide again there too.'),
        ]),
        guidePage('What do the map pins mean?', 1, [
          category('food', 'Food'),
          category('shopping', 'Shopping'),
          category('charityCommunityInfo', 'Charity/Community/Info'),
          category('performanceMusic', 'Music'),
          category('performanceChildrens', 'Childrens'),
          category('performanceDance', 'Dance'),
          category('performanceOther', 'Other'),
          category('visitExperience', 'Visit/Experience'),
          category('business', 'Business'),
          category('service', 'Service'),
          guideRow(
            Image.asset('assets/mapMarkers/mixedMarker.png', height: 40, width: 40, color: getCategoryColor(selectedThemeKey, 'Mixed')),
            Text('A mix of any of these categories', style: bodyStyle),
          ),
        ]),
        guidePage('Explore the map', 2, [
          tip(Icons.home, 'Tap the Home button on the map to zoom to the Fair.'),
          tip(Icons.radar, 'Tap the radar button to see your location and nearby pins.'),
          tip(Icons.satellite_alt, 'Switch between street and satellite maps as you prefer.'),
          tip(Icons.directions_walk, 'Open a listing and tap the walking icon for directions.'),
          tip(Icons.search, 'Search for stalls and events on the map.'),
          tip(Icons.filter_alt, 'Choose which types of attraction you want to appear on the map.'),
        ]),
        guidePage('Find what brings you to the Fair', 3, [
          tip(Icons.ballot, 'Tap Listings to browse everything at the Fair.'),
          tip(Icons.sort, 'Sort by name or location, or by Nearest. Time sorting is also available for performances.'),
          tip(Icons.info, 'Tap the info button to find out more about any listing.'),
          tip(Icons.favorite, 'Tap a listing’s heart icon to save it. It will then appear in your Favourites.'),
          tip(Icons.share, 'Share a listing with friends to tell them where you\'re headed.'),
          tip(Icons.event_busy, 'On the day of the Fair, performance lists and Favourites let you hide finished events or jump to what’s on now.'),
        ]),
        guidePage('Plan your day with the timetable', 3, [
          tip(Icons.watch_later, 'See performances and shorter visits and experiences by time and location.'),
          tip(Icons.pinch, 'Scroll across locations and up or down through the day. Pinch to adjust the timetable’s scale.'),
          tip(Icons.filter_alt, 'Tap the filter icon to cycle between music, non-music and everything.'),
          tip(Icons.schedule, 'On the day, tap the clock to show what’s on now or starting soon.'),
          tip(Icons.info, 'Tap an event for more details, or to save it.'),
        ]),
        guidePage('Make the app your own', 2, [
          tip(Icons.palette, 'In Settings choose one of our colourful themes. These include high contrast and colour blind friendly options.'),
          tip(Icons.straighten, 'Choose the units used for distances in Settings.'),
          tip(Icons.privacy_tip, 'You choose whether to allow anonymous usage analytics in Settings.'),
        ]),
        guidePage('A few final things…', 4, [
          tip(Icons.favorite, 'Thank you for visiting Mill Road Winter Fair and using our app.'),
          tip(Icons.update, 'Listings may change before the Fair, so check back for the latest details.'),
          guideRow(
            Icon(Icons.report, size: 40, color: colourScheme.onSecondary),
            Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Please read the '),
                  TextSpan(
                    text: 'important information',
                    style: const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        HapticFeedback.lightImpact();
                        widget.analyticsService.logButtonTapped('importantInfo_hyperlink');
                        Navigator.push(
                            context, MaterialPageRoute(builder: (context) => ImportantInfoPage(analyticsService: widget.analyticsService)));
                      },
                  ),
                  const TextSpan(text: ' about the Fair and its facilities.'),
                ]),
                style: bodyStyle),
          ),
          guideRow(
            Icon(Icons.diversity_1, size: 40, color: colourScheme.onSecondary),
            Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'The Fair is run entirely by volunteers. To get involved, visit our '),
                  TextSpan(
                    text: 'website',
                    style: const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        HapticFeedback.lightImpact();
                        widget.analyticsService.logButtonTapped('mrwf_website_hyperlink');
                        launchUrl(Uri.parse('https://www.millroadwinterfair.org/'));
                      },
                  ),
                  const TextSpan(text: '.'),
                ]),
                style: bodyStyle),
          ),
          guideRow(
            Icon(Icons.feedback, size: 40, color: colourScheme.onSecondary),
            Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'We’d love to hear your feedback about the app. Just fill in '),
                  TextSpan(
                    text: 'this form',
                    style: const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        HapticFeedback.lightImpact();
                        widget.analyticsService.logButtonTapped('app_feedback_hyperlink');
                        launchUrl(Uri.parse('https://www.millroadwinterfair.org/app-feedback-form/'));
                      },
                  ),
                  const TextSpan(text: '.'),
                ]),
                style: bodyStyle),
          ),
        ]),
      ],
      onDone: () {
        HapticFeedback.lightImpact();
        widget.analyticsService.logButtonTapped('done_WelcomeScreen');
        _onIntroEnd(context);
      },
      onSkip: () {
        HapticFeedback.lightImpact();
        widget.analyticsService.logButtonTapped('skip_text_WelcomeScreen');
        _onIntroEnd(context);
      },
      showSkipButton: true,
      skipOrBackFlex: 1,
      dotsFlex: 2,
      nextFlex: 1,
      showBackButton: false,
      back: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.tertiary),
      skip: FittedBox(
          fit: BoxFit.scaleDown, child: Text('Skip', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.tertiary))),
      overrideNext: (context, onPressed) => Tooltip(
        message: 'Next page',
        excludeFromSemantics: true,
        child: TextButton(
          onPressed: onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  widget.analyticsService.logButtonTapped('next_WelcomeScreen');
                  onPressed();
                },
          child: Icon(Icons.arrow_forward, semanticLabel: 'Next page', color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
      done: FittedBox(
          fit: BoxFit.scaleDown, child: Text('Done', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.tertiary))),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: kIsWeb ? const EdgeInsets.all(12.0) : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(6.0, 6.0),
        spacing: EdgeInsets.symmetric(horizontal: 2),
        color: Color(0xFFBDBDBD),
        activeSize: Size(14.0, 6.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        color: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}
