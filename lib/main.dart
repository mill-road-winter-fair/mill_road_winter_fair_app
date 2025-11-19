import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/gestures.dart';
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

// Define a GlobalKey for HomePageState to allow access from other parts of the app:
final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();

// Define a global variable for routing back to a previous index
int previousIndex = 0;
String appBarTitle = 'Mill Road Winter Fair 2025';

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
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) => runApp(firstExecution ? const WelcomeScreen() : const MyApp()));
}

// Define global variable as to whether we are onTest or not
bool onTest = false;

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

Widget contactUsDialog(BuildContext theBuildContext) {
  final ScrollController emailDetailsDialogScrollController = ScrollController();

  return Dialog(
    insetPadding: EdgeInsets.all(10.0 + ((MediaQuery.of(theBuildContext).size.height.toInt() - 500) / 50).toInt()),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(300.0, 500.0);
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.all(16.0 + ((MediaQuery.of(theBuildContext).size.height.toInt() - 500) / 50).toInt()),
            child: Scrollbar(
              controller: emailDetailsDialogScrollController,
              thumbVisibility: Platform.isIOS ? false : true, // iOS has its own scrollbar style
              thickness: 4,
              radius: const Radius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SingleChildScrollView(
                  controller: emailDetailsDialogScrollController,
                  primary: false,
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
                      const SizedBox(height: 15),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                                style: TextStyle(fontWeight: FontWeight.bold), text: 'For any important enquiries on the day of the Fair please phone '),
                            TextSpan(
                                text: '07303\u{00A0}142689',
                                style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    final Uri phoneUri = Uri(scheme: 'tel', path: '07303 142689');
                                    if (await canLaunchUrl(phoneUri)) {
                                      await launchUrl(phoneUri);
                                    } else {
                                      throw Exception('Could not dial 07303 142689');
                                    }
                                  }),
                            const TextSpan(style: TextStyle(fontWeight: FontWeight.bold), text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Close',
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
        decoration: TextDecoration.underline
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

  void setCurrentIndex(int newIndex) {
    setState(() {
      index = newIndex;
    });
  }

  // Fetch package information (from pubspec.yaml)
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  final _listingsKeyFood = GlobalKey<FilteredListingsPageState>();
  final _listingsKeyShopping = GlobalKey<FilteredListingsPageState>();
  final _listingsKeyMusic = GlobalKey<FilteredListingsPageState>();
  final _listingsKeyEvent = GlobalKey<FilteredListingsPageState>();
  final _listingsKeyPlace = GlobalKey<FilteredListingsPageState>();
  final _listingsKeyService = GlobalKey<FilteredListingsPageState>();
  
  late final _pages = [
    MapPage(listings: listings, key: mapPageKey),
    FilteredListingsPage(filterPrimaryType: "Food", listings: listings, key: _listingsKeyFood),
    FilteredListingsPage(filterPrimaryType: "Stalls", listings: listings, key: _listingsKeyShopping),
    FilteredListingsPage(filterPrimaryType: "Music", listings: listings, key: _listingsKeyMusic),
    FilteredListingsPage(filterPrimaryType: "Event", listings: listings, key: _listingsKeyEvent),
    FilteredListingsPage(filterPrimaryType: "Place", listings: listings, key: _listingsKeyPlace),
    FilteredListingsPage(filterPrimaryType: "Other", listings: listings, key: _listingsKeyService),
  ];

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
          title: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Android app by Alexander Berridge')),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('https://theberridge.com', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))),
          onTap: () async {
            HapticFeedback.lightImpact();
            launchUrl(Uri.parse('https://theberridge.com'));
          },
        ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone_iphone),
          title: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('iPhone version by Matt Whiting')),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('http://mattwhiting.com', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))),
          onTap: () async {
            HapticFeedback.lightImpact();
            launchUrl(Uri.parse('http://mattwhiting.com'));
          },
        ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.palette),
          title: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Illustrations by Clare McEwan')),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child:
                  Text('https://www.claremcewan.co.uk', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))),
          onTap: () async {
            HapticFeedback.lightImpact();
            launchUrl(Uri.parse('https://www.claremcewan.co.uk'));
          },
        ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.feedback),
          title: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Tell us if you like this app')),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Open a feedback form', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))),
          onTap: () async {
            HapticFeedback.lightImpact();
            launchUrl(Uri.parse('https://www.millroadwinterfair.org/app-feedback-form/'));
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(appBarTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
            switch (selectedIndex) {
              case 0 : if (homePageKey.currentState!.index != 0) appBarTitle = "Mill Road Winter Fair 2025";
              case 1 : _listingsKeyFood.currentState?.onTabVisible();
              case 2 : _listingsKeyShopping.currentState?.onTabVisible();
              case 3 : _listingsKeyMusic.currentState?.onTabVisible();
              case 4 : _listingsKeyEvent.currentState?.onTabVisible();
              case 5 : _listingsKeyPlace.currentState?.onTabVisible();
              case 6 : _listingsKeyService.currentState?.onTabVisible();
            }
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
            BottomNavigationBarItem(icon: Icon(Icons.home_work), label: "Places"),
            BottomNavigationBarItem(icon: Icon(Icons.wheelchair_pickup), label: "Other"),
          ],
        ),
      drawer: Drawer(
        child: Column(
          spacing: 0,
          children: <Widget>[
            Expanded(
              flex: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 380),
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 4, child: Container()),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Image.asset('assets/MRWF25_leaflet_banner.png', fit: BoxFit.contain),
                      ),
                      Expanded(flex: 2, child: Container()),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(' Saturday 6 December 2025 10.30 – 4.30',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(flex: 2, child: Container())
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About the Fair', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('Important information', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportantInfoPage()));
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Visit our website', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  launchUrl(Uri.parse('https://www.millroadwinterfair.org/'));
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Contact us', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return contactUsDialog(context);
                    },
                  );
                },
              ),
            ),
            Expanded(
              // needed as Expanded() is relative and this needs a fixed space on larger screens
              flex: max(((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt(), 1),
              child: const SizedBox.expand(),
            ),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      launchUrl(Uri.parse('https://www.facebook.com/MillRoadWinterFair/'));
                    },
                    icon: FaIcon(FontAwesomeIcons.squareFacebook, size: 40, color: Theme.of(context).colorScheme.tertiary),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      launchUrl(Uri.parse('https://x.com/millroadfair'));
                    },
                    icon: FaIcon(FontAwesomeIcons.squareXTwitter, size: 40, color: Theme.of(context).colorScheme.tertiary),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      launchUrl(Uri.parse('https://www.instagram.com/millroadwinterfair/'));
                    },
                    icon: FaIcon(FontAwesomeIcons.squareInstagram, size: 40, color: Theme.of(context).colorScheme.tertiary),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      launchUrl(Uri.parse('https://www.flickr.com/people/millroadwinterfair/'));
                    },
                    icon: FaIcon(FontAwesomeIcons.flickr, size: 40, color: Theme.of(context).colorScheme.tertiary),
                  ),
                ],
              ),
            ),
            const Expanded(
              flex: 2,
              child: SizedBox.expand(),
            ),
            const Expanded(
              flex: 0,
              child: Divider(),
            ),
            Expanded(
              flex: 4,
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('App guide', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WelcomeScreen()));
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About the app', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  aboutDialog();
                },
              ),
            ),
            const Expanded(
              flex: 2,
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
}
