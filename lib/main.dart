import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Declare googleApiKey after dotenv is loaded
late final String googleApiKey;

//Define a GlobalKey for MapPageState:
final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();

Future<void> main() async {
  await dotenv.load();
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  runApp(const MyApp());
}

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
  int _currentIndex = 0;

  Future<void> navigateToMapAndGetDirections(String plusCode) async {
    setState(() {
      _currentIndex = 0;
    });

    LatLng? coordinates =
        await getCoordinatesFromPlusCode(plusCode, googleApiKey);

    if (coordinates != null) {
      _mapPageKey.currentState?._getDirections(coordinates);
    }
  }

  final List<Widget> _pages = [
    const MapPage(),
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
  ];

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
        index: _currentIndex,
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
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
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

Future<Position> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    throw Exception("Location services are disabled.");
  }

  // Request permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception("Location permissions are denied.");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception("Location permissions are permanently denied.");
  }

  // Get current position
  return await Geolocator.getCurrentPosition();
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {}; // For displaying the route polyline
  late PolylinePoints polylinePoints; // For decoding points

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();
    fetchListings();
  }

  fetchListings() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/listings'));
    if (response.statusCode == 200) {
      final listings = json.decode(response.body);
      for (var listing in listings) {
        LatLng? coordinates =
            await getCoordinatesFromPlusCode(listing['plusCode'], googleApiKey);

        if (coordinates != null) {
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(listing['id'].toString()),
                position: coordinates,
                onTap: () {
                  // Show bottom sheet with listing information
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return ListingInfoSheet(
                        title: listing['displayName'],
                        categories: listing['secondaryType'] +
                            ' • ' +
                            listing['tertiaryType'],
                        openingTimes:
                            listing['startTime'] + ' - ' + listing['endTime'],
                        phoneNumber: listing['phone'],
                        website: listing['website'],
                        onGetDirections: () => _getDirections(coordinates),
                      );
                    },
                  );
                },
              ),
            );
          });
        }
      }
    }
  }

  Future<void> _getDirections(LatLng destination) async {
    // Get the user's current location
    Position position = await _getCurrentLocation();
    LatLng origin = LatLng(position.latitude, position.longitude);

    // Fetch directions from Google Directions API
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleApiKey,
      request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.walking),
    );

    // Check if route points were fetched successfully
    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.clear(); // Clear any existing route
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: const Color.fromRGBO(204, 51, 51, 1),
          width: 5,
        ));
      });
    } else {
      throw Exception("Failed to fetch directions");
    }
  }

// Helper function to get the current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception("Location services are disabled.");
    }

    // Request permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    // Get current position
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
      },
      initialCameraPosition: const CameraPosition(
        target:
            LatLng(52.199212, 0.139342), // Example coordinates for Mill Road
        zoom: 15,
      ),
      markers: _markers,
      polylines: _polylines, // Display polylines
    );
  }
}

class FilteredListingsPage extends StatelessWidget {
  final String filterPrimaryType;
  final String filterSecondaryType;

  const FilteredListingsPage({
    required this.filterPrimaryType,
    required this.filterSecondaryType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchFilteredListings(filterPrimaryType, filterSecondaryType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error fetching listings"));
        } else {
          final listings = snapshot.data as List;
          final homePageState =
              context.findAncestorStateOfType<HomePageState>();
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            separatorBuilder: (BuildContext context, int index) => Divider(color: Colors.grey[350]),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return ListingInfoSheet(
                title: listing['displayName'],
                categories:
                    listing['secondaryType'] + ' • ' + listing['tertiaryType'],
                openingTimes: listing['startTime'] + ' - ' + listing['endTime'],
                phoneNumber: listing['phone'],
                website: listing['website'],
                onGetDirections: () => {
                  if (homePageState != null)
                    {
                      homePageState
                          .navigateToMapAndGetDirections(listing['plusCode']),
                    }
                },
              );
            },
          );
        }
      },
    );
  }

  Future<List> fetchFilteredListings(
      String primaryType, String secondaryType) async {
    // Fetch all listings from the API
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/listings'));

    if (response.statusCode == 200) {
      // Decode the full list of listings
      final allListings = json.decode(response.body) as List;

      // Filter the listings based on the primaryType
      final filteredListings = allListings
          .where((listing) => listing['primaryType'] == primaryType)
          .toList();

      if (secondaryType.isNotEmpty) {
        return filteredListings
            .where((listing) => listing['secondaryType'] == secondaryType)
            .toList();
      }

      return filteredListings;
    } else {
      throw Exception("Failed to load listings");
    }
  }
}

class ListingInfoSheet extends StatelessWidget {
  final String title;
  final String categories;
  final String openingTimes;
  final String phoneNumber;
  final String website;
  final Function onGetDirections;

  const ListingInfoSheet({
    required this.title,
    required this.categories,
    required this.openingTimes,
    required this.phoneNumber,
    required this.website,
    required this.onGetDirections,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                openingTimes,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(categories),
          const SizedBox(height: 8),
          if (phoneNumber.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  throw Exception('Could not launch $phoneNumber');
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(phoneNumber),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  onGetDirections();
                },
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
              ),
              if (website.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    launchUrl(Uri.parse(website));
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('Open website'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Us")),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
            "Mill Road Winter Fair is an annual event ..."), // Add event details here
      ),
    );
  }
}

Future<LatLng?> getCoordinatesFromPlusCode(
    String plusCode, String apiKey) async {
  final encodedPlusCode = Uri.encodeComponent(plusCode);
  final url =
      'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$apiKey';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['results'] != null && data['results'].isNotEmpty) {
      final location = data['results'][0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
  }
  return null;
}
