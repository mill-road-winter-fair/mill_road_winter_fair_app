import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

// Initialise API Key variables
late String googleApiKey;
late String mrwfApi;

//Set the default page number (0 is the map page)
int globalIndex = 0;

Future<void> main() async {
  // Ensure all bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  mrwfApi = dotenv.env['MRWF_API'] ?? '';

  await loadSettings(false);

  // Run the app
  runApp(const MyApp());
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
  int get currentIndex => globalIndex;

  Future<void> navigateToMapAndGetDirections(int id, LatLng destinationCoordinates, http.Client client) async {
    setState(() {
      globalIndex = 0;
    });

    mapPageKey.currentState?.getDirections(id, destinationCoordinates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mill Road Winter Fair'),
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
        index: globalIndex,
        children: [
          MapPage(key: mapPageKey),
          FilteredListingsPage(filterPrimaryType: "Food", client: http.Client()),
          FilteredListingsPage(filterPrimaryType: "Shopping", client: http.Client()),
          FilteredListingsPage(filterPrimaryType: "Music", client: http.Client()),
          FilteredListingsPage(filterPrimaryType: "Event", client: http.Client()),
          FilteredListingsPage(filterPrimaryType: "Service", client: http.Client()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: globalIndex,
        onTap: (index) {
          // Update the user's location
          establishLocation();
          setState(() {
            globalIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: "Food"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Shopping"),
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
                  DrawerHeader(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Mill Road Winter Fair',
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 28),
                      ],
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
