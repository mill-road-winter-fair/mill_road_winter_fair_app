import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/chooser_page.dart';
import 'package:mill_road_winter_fair_app/timetable_page.dart';

Future<void> main() async {
  debugPrint('App starting: main() called');
  // Ensure all bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  await loadSettings();
  debugPrint('Settings loaded');

  listings = await fetchListings(http.Client());
  debugPrint('Listings fetched: count = ${listings.length}');

  // Check whether location services are enabled and permissions are granted to the app
  locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
  locationPermission = await Geolocator.checkPermission();
  debugPrint('Location services enabled: $locationServicesEnabled, permission: $locationPermission');

  // Lock app in portrait rotation and run main app
  // If this is the first execution run the welcome screen, otherwise just run the app normally
  debugPrint('Setting preferred orientation and running app');
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) => runApp(const RootWidget()));
}

class RootWidget extends StatelessWidget {
  const RootWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return firstExecution ? const WelcomeScreen() : const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('MyApp build() called');
    return ValueListenableBuilder<String>(
      valueListenable: themeNotifier,
      builder: (context, selectedThemeKey, _) {
        debugPrint('Theme changed: $selectedThemeKey');
        return MaterialApp(
          title: 'Mill Road Winter Fair',
          theme: appThemes[selectedThemeKey],
          home: HomePage(key: homePageKey),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  
  int index = 0;
  bool timetableOnlyNowOrSoon = false;
  bool? timetableFilteredMusicOrNot;

  @override
  void initState() {
    super.initState();
  }

  void setCurrentIndex(int newIndex) {
    setState(() {
      index = newIndex;
    });
  }

  void openTimetable(bool onlyNowOrSoon, bool? filteredMusicOrNot) {
    setState(() {
      timetableFilteredMusicOrNot = filteredMusicOrNot;
      timetableOnlyNowOrSoon = onlyNowOrSoon;
      index = 2;
    });
  }

  void timetableFilterChange(bool newOnlyNowOrSoon, newFilteredMusicOrNot) {
    debugPrint('HomePageState timetableFilterChange called with newOnlyNowOrSoon=$newOnlyNowOrSoon newFilteredMusicOrNot=$newFilteredMusicOrNot');
    setState(() {
      timetableFilteredMusicOrNot = newFilteredMusicOrNot;
      timetableOnlyNowOrSoon = newOnlyNowOrSoon;
    });
  }

  final _allListingsKey = GlobalKey<FilteredListingsPageState>();
  final _savedListingsKey = GlobalKey<FilteredListingsPageState>();
  
  @override
  Widget build(BuildContext context) {
    final pages = [
      ChooserPage(theEvents: listings, onTabSelected: setCurrentIndex, onOpenTimetable: openTimetable),
      MapPage(listings: listings, key: mapPageKey, onTabSelected: setCurrentIndex),
      TimetablePage(theEvents: listings, onTabSelected: setCurrentIndex, filteredMusicOrNot: timetableFilteredMusicOrNot, onlyNowOrSoon: timetableOnlyNowOrSoon, onFilterChange: timetableFilterChange),
      FilteredListingsPage(filterCategory: "all", listings: listings, key: _allListingsKey, onTabSelected: setCurrentIndex),
      FilteredListingsPage(filterCategory: "favourite", listings: listings, key: _savedListingsKey, onTabSelected: setCurrentIndex),
    ];
    return IndexedStack(
      index: index,
      children: pages,
    );
  }
}
