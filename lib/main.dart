import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

Future<void> main() async {
  // Ensure all bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  await loadSettings(false);

  listings = await fetchListings(http.Client());

  // Check whether location services are enabled and permissions are granted to the app
  locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
  locationPermission = await Geolocator.checkPermission();

  // Lock app in portrait rotation and run main app
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) => runApp(firstExecution ? const WelcomeScreen() : const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: themeNotifier,
      builder: (context, selectedThemeKey, _) {
        return MaterialApp(
          title: 'Mill Road Winter Fair',
          theme: appThemes[selectedThemeKey],
          home: const HomePage(),
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

  Future<void> navigateToMapAndGetDirections(String id, LatLng destinationCoordinates, http.Client client) async {
    setState(() {
      index = 0;
    });

    mapPageKey.currentState?.getDirections(id, destinationCoordinates, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Mill Road Winter Fair 2025', style: TextStyle(fontSize: 20)),
            Image.asset('assets/iconTransparent.png', height: 30, width: 30, color: Theme.of(context).colorScheme.onPrimary),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      body: IndexedStack(
        index: index,
        children: [
          MapPage(listings: listings, key: mapPageKey),
          FilteredListingsPage(filterPrimaryType: "Food", listings: listings),
          FilteredListingsPage(filterPrimaryType: "Shopping", listings: listings),
          FilteredListingsPage(filterPrimaryType: "Music", listings: listings),
          FilteredListingsPage(filterPrimaryType: "Event", listings: listings),
          FilteredListingsPage(filterPrimaryType: "Service", listings: listings),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        currentIndex: index,
        onTap: (selectedIndex) {
          // Update the user's location
          establishLocation();
          setState(() {
            index = selectedIndex;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: "Food"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "Stalls"),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: "Music"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.wheelchair_pickup), label: "Services"),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 480),
                    child: DrawerHeader(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 4, child: Container()),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Mill Road Winter Fair 2025',
                              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(flex: 1, child: Container())
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About the Fair', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.warning),
                    title: const Text('Important Info', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportantInfoPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: const Text('Visit our website', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      launchUrl(Uri.parse('https://www.millroadwinterfair.org/'));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email us', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final Uri mailUri = Uri(scheme: 'mailto', path: 'info@millroadwinterfair.org');
                      if (await canLaunchUrl(mailUri)) {
                        await launchUrl(mailUri);
                      } else {
                        throw Exception('Could not launch email client');
                      }
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: FractionalOffset.bottomCenter,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          launchUrl(Uri.parse('https://www.facebook.com/MillRoadWinterFair/'));
                        },
                        icon: FaIcon(FontAwesomeIcons.squareFacebook, size: 60, color: Theme.of(context).colorScheme.tertiary),
                      ),
                      IconButton(
                        onPressed: () {
                          launchUrl(Uri.parse('https://x.com/millroadfair'));
                        },
                        icon: FaIcon(FontAwesomeIcons.squareXTwitter, size: 60, color: Theme.of(context).colorScheme.tertiary),
                      ),
                      IconButton(
                        onPressed: () {
                          launchUrl(Uri.parse('https://www.instagram.com/millroadwinterfair/'));
                        },
                        icon: FaIcon(FontAwesomeIcons.squareInstagram, size: 60, color: Theme.of(context).colorScheme.tertiary),
                      ),
                      IconButton(
                        onPressed: () {
                          launchUrl(Uri.parse('https://www.flickr.com/people/millroadwinterfair/'));
                        },
                        icon: FaIcon(FontAwesomeIcons.flickr, size: 60, color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.feedback),
                    title: const Text('Give feedback about the app', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      launchUrl(Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSehyC3H9mCzVP3Ao5Tl2-fv-mIVS73hN7BLriif80LQ6vRv8w/viewform?usp=sf_link'));
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
