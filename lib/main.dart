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
  // the following need to be in HomePageState to allow deep linking to configured pages
  bool timetableOnlyNowOrSoon = false; // toggled on or off to show events now or in next hour
  bool? timetableFilteredMusicOrNot; // toggled on (just music), off (all but music), null (all)
  String? listingsSubfilterCategory; // all listings visible (null) or just the one category
  int? mapNearestMarkerCount; // when opening the map, zoom in to this number nearby

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

  void openListings(String filterCategory, String? subfilterCategory) {
    setState(() {
      listingsSubfilterCategory = subfilterCategory;
      index = (filterCategory == 'favourite') ? 4 : 3;
    });
  }

  void openMap(int? nearestMarkerCount) {
    setState(() {
      mapNearestMarkerCount = nearestMarkerCount;
      index = 1;
    });
  }

  void cancelMapNearest() {
    debugPrint('HomePageState cancelMapNearest called');
    setState(() {
      mapNearestMarkerCount = null;
    });
  }

  void timetableFilterChange(bool newOnlyNowOrSoon, newFilteredMusicOrNot) {
    debugPrint('HomePageState timetableFilterChange called with newOnlyNowOrSoon=$newOnlyNowOrSoon newFilteredMusicOrNot=$newFilteredMusicOrNot');
    setState(() {
      timetableFilteredMusicOrNot = newFilteredMusicOrNot;
      timetableOnlyNowOrSoon = newOnlyNowOrSoon;
    });
  }

  void listingsSubfilterChange(String? newSubfilterCategory) {
    debugPrint('HomePageState listingsSubfilterChange called with newSubfilterCategory=$newSubfilterCategory');
    setState(() {
      listingsSubfilterCategory = newSubfilterCategory;
    });
  }

  final _allListingsKey = GlobalKey<FilteredListingsPageState>();
  final _savedListingsKey = GlobalKey<FilteredListingsPageState>();
  
  @override
  Widget build(BuildContext context) {
    final pages = [
      ChooserPage(theEvents: listings, onTabSelected: setCurrentIndex, onOpenTimetable: openTimetable, onOpenListings: openListings, onOpenMap: openMap),
      MapPage(listings: listings, key: mapPageKey, nearestMarkerCount: mapNearestMarkerCount, onTabSelected: setCurrentIndex, onHomeTapped: cancelMapNearest),
      TimetablePage(theEvents: listings, onTabSelected: setCurrentIndex, filteredMusicOrNot: timetableFilteredMusicOrNot, onlyNowOrSoon: timetableOnlyNowOrSoon, onFilterChange: timetableFilterChange),
      FilteredListingsPage(filterCategory: "all", subfilterCategory: listingsSubfilterCategory, listings: listings, key: _allListingsKey, onTabSelected: setCurrentIndex, onSubfilterChange: listingsSubfilterChange),
      FilteredListingsPage(filterCategory: "favourite", subfilterCategory: listingsSubfilterCategory, listings: listings, key: _savedListingsKey, onTabSelected: setCurrentIndex, onSubfilterChange: listingsSubfilterChange),
    ];
    return IndexedStack(
      index: index,
      children: pages,
    );
  }
}
