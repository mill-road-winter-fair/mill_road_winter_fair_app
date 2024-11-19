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

//Initialize API Key variables
late String googleApiKey;
late String mrwfApi;

//Define a GlobalKey for MapPageState:
final GlobalKey<MapPageState> mapPageKey = GlobalKey<MapPageState>();

//Set the default page number (0 is the map page)
int globalIndex = 0;

Future<void> main() async {
  // Ensure all bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  mrwfApi = dotenv.env['MRWF_API'] ?? '';

  // Load user preferences
  await loadSettings();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: themeNotifier,
      builder: (context, themeKey, _) {
        return MaterialApp(
          title: 'Mill Road Winter Fair',
          theme: appThemes[themeKey],
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 195,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mill Road Winter Fair',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        launchUrl(Uri.parse('https://www.millroadwinterfair.org/'));
                      },
                      icon: const Icon(Icons.public),
                      label: const Text('Visit our website'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final Uri mailUri = Uri(scheme: 'mailto', path: 'info@millroadwinterfair.org');
                        if (await canLaunchUrl(mailUri)) {
                          await launchUrl(mailUri);
                        } else {
                          throw Exception('Could not launch email client');
                        }
                      },
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Email us'),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text('About the Fair', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
              },
            ),
            ListTile(
              title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
