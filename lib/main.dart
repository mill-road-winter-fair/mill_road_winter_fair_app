import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
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
  debugPrint('App starting: main() called');
  // Ensure all bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  await loadSettings(false);
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
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) => runApp(firstExecution ? const WelcomeScreen() : const MyApp()));
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
          home: const HomePage(),
        );
      },
    );
  }
}

Widget emailDetailsDialog() {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.clamp(300.0, 500.0);
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('For general enquiries:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildEmailLink('info@millroadwinterfair.org'),
                  const SizedBox(height: 15),
                  const Text('If you would like to volunteer:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildEmailLink('volunteers@millroadwinterfair.org'),
                  const SizedBox(height: 15),
                  const Text('Enquiries regarding events or busking:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildEmailLink('events@millroadwinterfair.org'),
                  const SizedBox(height: 15),
                  const Text('Enquiries regarding vendors:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildEmailLink('stalls@millroadwinterfair.org'),
                  const SizedBox(height: 15),
                  const Text('Enquiries regarding the website:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildEmailLink('it@millroadwinterfair.org'),
                  const SizedBox(height: 15),
                  const Text('Enquiries regarding the app:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildEmailLink('app@millroadwinterfair.org'),
                  const SizedBox(height: 45),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailLink(String email) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final Uri mailUri = Uri(scheme: 'mailto', path: email);
        if (await canLaunchUrl(mailUri)) {
          await launchUrl(mailUri);
        } else {
          throw Exception('Could not launch email client');
        }
      },
      child: Text(
        email,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int index = 0;

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  // Fetch package information (from pubspec.yaml)
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> navigateToMapAndGetDirections(String id, LatLng destinationCoordinates, http.Client client) async {
    setState(() {
      index = 0;
      mapPageKey.currentState?.getDirections(id, destinationCoordinates, false);
    });
  }

  void aboutDialog() {
    return showAboutDialog(
      context: context,
      applicationName: 'Mill Road\nWinter Fair',
      applicationVersion: _packageInfo.version,
      applicationIcon: const MyAppIcon(),
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone_android),
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Android app by Alex Berridge')
          ),
          subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('http://theberridge.com', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))
          ),
          onTap: () async {
            HapticFeedback.lightImpact();
            launchUrl(Uri.parse('http://theberridge.com'));
          },
        ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone_iphone),
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('iPhone version by Matt Whiting')
          ),
          subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('http://mattwhiting.com', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))
          ),
          onTap: () async {
            HapticFeedback.lightImpact();
            launchUrl(Uri.parse('http://mattwhiting.com'));
          },
        ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.feedback),
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Tell us if you like this app')
          ),
          subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Open a feedback form', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))
          ),
          onTap: () async {
            HapticFeedback.lightImpact();
            launchUrl(Uri.parse(
                'https://docs.google.com/forms/d/e/1FAIpQLSehyC3H9mCzVP3Ao5Tl2-fv-mIVS73hN7BLriif80LQ6vRv8w/viewform?usp=sf_link'));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
              },
          ),
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Mill Road Winter Fair 2025', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        actions: [
          IconButton(
            icon: const ImageIcon(AssetImage('assets/icons/iconTransparent.png')),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
            },
          ),
        ],
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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(right: 10),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
          currentIndex: index,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 30,
          onTap: (selectedIndex) {
            HapticFeedback.selectionClick();
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
        )
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
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Mill Road Winter Fair 2025', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 19, fontWeight: FontWeight.bold)),
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
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.warning),
                    title: const Text('Important information', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      Navigator.push(context,MaterialPageRoute(builder: (context) => const ImportantInfoPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: const Text('Visit our Website', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      launchUrl(Uri.parse('https://www.millroadwinterfair.org/'));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email us', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => emailDetailsDialog(),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: FractionalOffset.topCenter,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse('https://www.facebook.com/MillRoadWinterFair/'));
                        },
                        icon: FaIcon(FontAwesomeIcons.squareFacebook, size: 60, color: Theme.of(context).colorScheme.tertiary),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse('https://x.com/millroadfair'));
                        },
                        icon: FaIcon(FontAwesomeIcons.squareXTwitter, size: 60, color: Theme.of(context).colorScheme.tertiary),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse('https://www.instagram.com/millroadwinterfair/'));
                        },
                        icon: FaIcon(FontAwesomeIcons.squareInstagram, size: 60, color: Theme.of(context).colorScheme.tertiary),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
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
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.first_page),
                    title: const Text('Replay welcome screen', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WelcomeScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About the app', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      aboutDialog();
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

