import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('WelcomeScreen build() called');
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    return MaterialApp(
      title: 'Welcome screen',
      debugShowCheckedModeBanner: false,
      theme: appThemes[selectedThemeKey],
      home: const OnBoardingPage(),
    );
  }
}

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  OnBoardingPageState createState() => OnBoardingPageState();
}

class OnBoardingPageState extends State<OnBoardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstExecution', false);
  }

  void _onIntroEnd(context) {
    _saveSettings();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MyApp()),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('OnBoardingPageState build() called');
    var bodyStyle = TextStyle(fontSize: 19, color: Theme.of(context).colorScheme.onSecondary);

    var pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary),
      bodyTextStyle: TextStyle(fontSize: 19, color: Theme.of(context).colorScheme.onSecondary),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Theme.of(context).colorScheme.secondary,
    );

    return IntroductionScreen(
      key: introKey,
      autoScrollDuration: 150000,
      globalBackgroundColor: Theme.of(context).colorScheme.secondary,
      allowImplicitScrolling: true,
      infiniteAutoScroll: true,
      globalFooter: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 28),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.tertiary),
            child: Text(
              'Take me straight to the app!',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              _onIntroEnd(context);
            },
          ),
        ),
      ),
      pages: [
        PageViewModel(
          useScrollView: false,
          backgroundImage: 'assets/welcomeScreen/clareMcEwan_artwork00.jpg',
          title: "Welcome to the official\nMill Road Winter Fair app!",
          bodyWidget: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight, // respect available space
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown, // shrink contents if needed
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("What can I do with the app?",
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(Icons.map, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Use our interactive map to help\nnavigate the Fair’s attractions", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("See listings of the Fair’s various\nstalls, events and facilities", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.language, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Find the websites and social\nlinks for the Fair and its stalls", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.info, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Find out important and useful\ninformation about the Fair", style: bodyStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 0,
            safeArea: 160, // padding at bottom to avoid nav bar
            pageColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
          ),
        ),
        PageViewModel(
          useScrollView: false,
          backgroundImage: 'assets/welcomeScreen/clareMcEwan_artwork01.jpg',
          title: "What do the pins mean?",
          bodyWidget: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight, // respect available space
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown, // shrink contents if needed
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fastfood, size: 40, color: getCategoryColor(selectedThemeKey, "Food")),
                          const SizedBox(width: 8),
                          Text("Our delicious ready-to-eat food\nand drink stalls and trucks", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 40, color: getCategoryColor(selectedThemeKey, "Shopping")),
                          const SizedBox(width: 8),
                          Text("The stalls of the various shops,\ncharities and other organisations", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.music_note, size: 40, color: getCategoryColor(selectedThemeKey, "Music")),
                          const SizedBox(width: 8),
                          Text("The Fair’s amazing and talented\nmusicians, buskers and bands", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.event, size: 40, color: getCategoryColor(selectedThemeKey, "Event")),
                          const SizedBox(width: 8),
                          Text("Other exciting events, such as\nSanta’s Grotto and the parade", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.wheelchair_pickup, size: 40, color: getCategoryColor(selectedThemeKey, "Service")),
                          const SizedBox(width: 8),
                          Text("All our important services, such\nas toilets and first aid points", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Image.asset('assets/mapMarkers/genericGroupMarker.png', height: 40, width: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Wide pins show where there’s\nmore than one thing at a location", style: bodyStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 0,
            safeArea: 160, // padding at bottom to avoid nav bar
            pageColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
          ),
        ),
        PageViewModel(
          useScrollView: false,
          backgroundImage: 'assets/welcomeScreen/clareMcEwan_artwork02.jpg',
          title: "Choosing what’s shown",
          bodyWidget: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight, // respect available space
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown, // shrink contents if needed
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.filter_alt, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("First tap the filter icon on\nthe map page", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.check_box_outlined, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Then simply select the\ncategories you want to see", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.map, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("When you tap back on the map\nonly those will be showing", style: bodyStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 0,
            safeArea: 160, // padding at bottom to avoid nav bar
            pageColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
          ),
        ),
        PageViewModel(
          useScrollView: false,
          backgroundImage: 'assets/welcomeScreen/clareMcEwan_artwork03.jpg',
          title: "What’s on and when",
          bodyWidget: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight, // respect available space
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown, // shrink contents if needed
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.smart_button, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text(
                              "There’s a button for each listings\ncategory at the bottom of the app",
                              style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.list_alt, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Tap on these to see everything\nthat’s on in that category", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.sort, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("You can sort the list by distance\nfrom you or start time", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.search, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Tap the search icon and type to\nfind specific listings", style: bodyStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 0,
            safeArea: 160, // padding at bottom to avoid nav bar
            pageColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
          ),
        ),
        PageViewModel(
          useScrollView: false,
          backgroundImage: 'assets/welcomeScreen/clareMcEwan_artwork04.jpg',
          title: "A few final things…",
          bodyWidget: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight, // respect available space
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown, // shrink contents if needed
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Thank you for visiting Mill Road\nWinter Fair and using our new app", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.report, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: "Please do make sure you’ve read the\n",
                                    style: bodyStyle),
                                TextSpan(text:  "important information",
                                  style: bodyStyle.copyWith(decoration: TextDecoration.underline), 
                                  recognizer: TapGestureRecognizer()..onTap = () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportantInfoPage()));
                                  },
                                ),
                                TextSpan(text: " about the Fair",
                                    style: bodyStyle),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.diversity_1, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: "Did you know the Fair is organised\nentirely by volunteers? To get\ninvolved, just visit our ",
                                    style: bodyStyle),
                                TextSpan(text:  "website",
                                  style: bodyStyle.copyWith(decoration: TextDecoration.underline), 
                                  recognizer: TapGestureRecognizer()..onTap = () { 
                                    HapticFeedback.lightImpact();
                                    launchUrl(Uri.parse('https://www.millroadwinterfair.org/')); 
                                    },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.feedback, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: "If you have feedback about the app\nwe’d love to hear from you!\nJust fill in ",
                                    style: bodyStyle),
                                TextSpan(text:  "this form",
                                  style: bodyStyle.copyWith(decoration: TextDecoration.underline), 
                                  recognizer: TapGestureRecognizer()..onTap = () { 
                                    HapticFeedback.lightImpact();
                                    launchUrl(Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSehyC3H9mCzVP3Ao5Tl2-fv-mIVS73hN7BLriif80LQ6vRv8w/viewform?usp=sf_link')); 
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 0,
            safeArea: 160, // padding at bottom to avoid nav bar
            pageColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
          ),
        ),
      ],
      onDone: () {
        HapticFeedback.lightImpact();
        _onIntroEnd(context);
      },
      onSkip: () {
        HapticFeedback.lightImpact();
        _onIntroEnd(context);
      },
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.tertiary),
      skip: Text('Skip', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.tertiary)),
      next: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.tertiary),
      done: Text('Done', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.tertiary)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: kIsWeb ? const EdgeInsets.all(12.0) : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
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
