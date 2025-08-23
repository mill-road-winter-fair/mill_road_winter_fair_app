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

  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset('assets/welcomeScreen/$assetName', width: width);
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);

    var pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSecondary),
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Theme.of(context).colorScheme.secondary,
      imagePadding: EdgeInsets.zero,
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
          title: "Welcome to the official\nMill Road Winter Fair app!",
          backgroundImage: 'assets/aboutPage/carousel01.jpg',
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("What can I do with the app?", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: Icon(Icons.map, size: 40, color: Theme.of(context).colorScheme.onSecondary)),
                  const Expanded(flex: 8, child: Text("Use our interactive map to help navigate the fair's attractions", style: bodyStyle)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: Icon(Icons.storefront, size: 40, color: Theme.of(context).colorScheme.onSecondary)),
                  const Expanded(flex: 8, child: Text("See listings of the fair's various stalls, events and facilities", style: bodyStyle)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: Icon(Icons.language, size: 40, color: Theme.of(context).colorScheme.onSecondary)),
                  const Expanded(flex: 8, child: Text("Find the websites and social links for the fair and its stalls", style: bodyStyle)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: Icon(Icons.info, size: 40, color: Theme.of(context).colorScheme.onSecondary)),
                  const Expanded(flex: 8, child: Text("Find out important information about the fair", style: bodyStyle)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 10,
            imageFlex: 3,
            safeArea: 100,
            bodyTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
        ),
        PageViewModel(
          title: "Map Pins",
          body: "What are the map pins and what do they mean?",
          backgroundImage: 'assets/aboutPage/carousel02.jpg',
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 6,
            imageFlex: 3,
            safeArea: 100,
          ),
        ),
        PageViewModel(
          title: "Filtering",
          body: "How can I filter the stalls/events?",
          backgroundImage: 'assets/aboutPage/carousel03.jpg',
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 6,
            imageFlex: 3,
            safeArea: 100,
          ),
        ),
        PageViewModel(
          title: "Listings",
          body: "What are the listings pages for?",
          backgroundImage: 'assets/aboutPage/carousel04.jpg',
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 6,
            imageFlex: 3,
            safeArea: 100,
          ),
        ),
        PageViewModel(
          title: "That's all",
          body: "We hope you enjoy...",
          backgroundImage: 'assets/aboutPage/carousel01.jpg',
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 6,
            imageFlex: 3,
            safeArea: 100,
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
