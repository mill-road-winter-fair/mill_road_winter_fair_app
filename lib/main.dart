import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/about_us.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/plus_code_handlers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//Initialize API Key variables
late String googleApiKey;
late String mrwfApi;

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  mrwfApi = dotenv.env['MRWF_API'] ?? '';
  runApp(const MyApp());
}

//Define a GlobalKey for MapPageState:
final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();

//Set the default page number (0 is the map page)
int currentIndex = 0;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mill Road Winter Fair',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color.fromRGBO(204, 51, 51, 1),
          onPrimary: Colors.black,
          secondary: Colors.yellow,
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(204, 51, 51, 1),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color.fromRGBO(204, 51, 51, 1),
          unselectedItemColor: Colors.grey,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color.fromRGBO(204, 51, 51, 1),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  Future<void> navigateToMapAndGetDirections(int id, String plusCode) async {
    setState(() {
      currentIndex = 0;
    });

    LatLng? coordinates =
        await getCoordinatesFromPlusCode(plusCode, googleApiKey);

    if (coordinates != null) {
      _mapPageKey.currentState?.getDirections(id, coordinates);
    }
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
        index: currentIndex,
        children: [
          MapPage(key: _mapPageKey),
          const FilteredListingsPage(
              filterPrimaryType: "Vendor", filterSecondaryType: "Food"),
          const FilteredListingsPage(
              filterPrimaryType: "Vendor", filterSecondaryType: "Retail"),
          const FilteredListingsPage(
              filterPrimaryType: "Performer", filterSecondaryType: ""),
          const FilteredListingsPage(
              filterPrimaryType: "Event", filterSecondaryType: ""),
          const FilteredListingsPage(
              filterPrimaryType: "Service", filterSecondaryType: ""),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: "Food"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: "Shopping"),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: "Music"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(
              icon: Icon(Icons.wheelchair_pickup), label: "Services"),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Text('Menu'),
            ),
            ListTile(
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutUsPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
