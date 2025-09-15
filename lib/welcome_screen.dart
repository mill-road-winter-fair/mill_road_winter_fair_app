import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
  Widget build(BuildContext context) {
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
      globalBackgroundColor: Colors.white,
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
            onPressed: () => _onIntroEnd(context),
          ),
        ),
      ),
      pages: [
        PageViewModel(
          useScrollView: false,
          backgroundImage: 'assets/aboutPage/carousel01.jpg',
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
                          Text("Use our interactive map to help\nnavigate the fair's attractions", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("See listings of the fair's various\nstalls, events and facilities", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.language, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Find the websites and social\nlinks for the fair and its stalls", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.info, size: 40, color: Theme.of(context).colorScheme.onSecondary),
                          const SizedBox(width: 8),
                          Text("Find out important information\nabout the fair", style: bodyStyle),
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
          backgroundImage: 'assets/aboutPage/carousel02.jpg',
          title: "Map Pins",
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
                      Text("What do the map pins mean?",
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(Icons.fastfood, size: 40, color: getCategoryColor(selectedThemeKey, "Food")),
                          const SizedBox(width: 8),
                          Text("Our delicious ready-to-eat food\nstalls and food trucks", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 40, color: getCategoryColor(selectedThemeKey, "Shopping")),
                          const SizedBox(width: 8),
                          Text("The stalls of all the various shops,\ncharities and other organisations", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.music_note, size: 40, color: getCategoryColor(selectedThemeKey, "Music")),
                          const SizedBox(width: 8),
                          Text("The fair's amazing and talented\nmusicians, buskers and bands", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.event, size: 40, color: getCategoryColor(selectedThemeKey, "Event")),
                          const SizedBox(width: 8),
                          Text("Other exciting events, such as\nSanta's Grotto and the parade", style: bodyStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.wheelchair_pickup, size: 40, color: getCategoryColor(selectedThemeKey, "Service")),
                          const SizedBox(width: 8),
                          Text("All of our important services, such\nas toilets and first aid points", style: bodyStyle),
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
          backgroundImage: 'assets/aboutPage/carousel03.jpg',
          title: "Filtering",
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
                      FittedBox(
                        child: Text("How can I filter all those pins?",
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary)),
                      ),
                      const SizedBox(height: 18),
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
          title: "Listings",
          backgroundImage: 'assets/aboutPage/carousel04.jpg',
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                child: Text("How can I see a list of what's on?",
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: Icon(Icons.list_alt, size: 40, color: Theme.of(context).colorScheme.onSecondary)),
                  const Expanded(
                    flex: 8,
                    child: Text(
                      "At the bottom of the app you'll see sections for each different category. Tap on these to see every listing for that category",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: Icon(Icons.sort, size: 40, color: Theme.of(context).colorScheme.onSecondary)),
                  const Expanded(flex: 8, child: Text("You can then sort these listings by distance, start time or alphabetical order")),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 8,
            imageFlex: 3,
            safeArea: 160,
            pageColor: Theme.of(context).colorScheme.secondary,
            titleTextStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary),
            bodyTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
        ),
        PageViewModel(
          title: "Almost there!",
          backgroundImage: 'assets/aboutPage/carousel01.jpg',
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                child: Text("A few final things...",
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: Icon(Icons.favorite, size: 40, color: Theme.of(context).colorScheme.onSecondary)),
                  const Expanded(flex: 8, child: Text("Thank you so much for visiting Mill Road Winter Fair and using our new app.")),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: Icon(Icons.diversity_1, size: 40, color: Theme.of(context).colorScheme.onSecondary)),
                  const Expanded(
                    flex: 8,
                    child: Text(
                      "Did you know the fair is organised entirely by volunteers? If you'd like to get involved visit our website.",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: Icon(Icons.feedback, size: 40, color: Theme.of(context).colorScheme.onSecondary)),
                  const Expanded(
                    flex: 8,
                    child: Text(
                      "If you have feedback about the app we'd love to hear from you! You can find a link to our feedback form at the bottom of the app's main menu.",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 12,
            imageFlex: 3,
            safeArea: 160,
            pageColor: Theme.of(context).colorScheme.secondary,
            titleTextStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary),
            bodyTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // You can override onSkip callback
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
