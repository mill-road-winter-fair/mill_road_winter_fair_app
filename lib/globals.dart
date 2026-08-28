import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';

// Consolidated global variables used across the app.
// Move only top-level variables here so other files can import a single source.

// GlobalKeys for accessing state of various pages from other parts of the app:
final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();
final GlobalKey<MapPageState> mapPageKey = GlobalKey<MapPageState>();

// Remember the previously selected bottom navigation index (used for back navigation).
int previousIndex = 0;

// Flag set by tests (when true the app reduces/delays animation and timers).
bool onTest = false;

// The cached list of listings fetched from the remote API.
List<Map<String, dynamic>> listings = [];

// Whether map navigation is currently active.
bool navigationInProgress = false;

// Identifier for a simple (non-group) marker.
const String aSimpleMarkerId = 'SIMPLE';

// API key for Google Maps Directions. Populated at runtime from dotenv.
String googleMapsDirectionsApiKey = "";

// --- Settings and preferences (moved from settings_page.dart) ---
// Whether this is the first execution of the app (controls welcome screen flow).
late bool firstExecution;

// Map orientation options (moved from settings_page.dart so globals can hold the values).
enum MapOrientation { adaptive, alwaysNorth }

// Preferred map orientation value.
late MapOrientation preferredMapOrientation;

// Map style options.
enum MapStyleType { normal, hybrid }

// The user's preferred map style type.
late MapStyleType preferredMapStyleType;

// Define available sorting methods
enum SortingMethod { alphabetical, nearest, startTime, location }

// Define variable for sorting method
late SortingMethod preferredSortingMethod;

// Define available distance units
enum DistanceUnits { metric, imperial, cambridge }

// Set default distance units
late DistanceUnits preferredDistanceUnits;

// Initialise theme variables
late String selectedThemeKey;
late ValueNotifier<String> themeNotifier;

// Initialise map style variable to store map styling json
late String mapStyle;

// Initialise setting for whether the road closure polygon is shown
late bool preferredRoadClosurePolygonVisible;

// Initialise the list of favourited listings
late Set<String> favouriteListingKeys;

// --- Location related globals (moved from get_current_location.dart) ---
// Whether device location services are enabled and the permission status.
late bool locationServicesEnabled;
late LocationPermission locationPermission;

// Small counter to limit how often we prompt the user to enable location services.
int promptedUserToEnableLocationServices = 0;

// Cached user location used by the map and listings pages.
LatLng? currentLatLng;

// Fair date (and times) for this year
// Also used by the listing-update notifier.
final fairDate = DateTime(2026, 12, 5);
const fairDateTimes = 'Saturday 5 December 2026 10:30—16:30';

// Title used for appbar
const fairName = 'Mill Road Winter Fair 2026';
String appBarTitle = fairName; // this may be changed in main, filtered_listings etc.

// Road closure coordinates rounded to 6 decimal places (~0.1 m precision).
final List<LatLng> roadClosurePolygonPoints = [
  const LatLng(52.202353, 0.131062),
  const LatLng(52.202315, 0.131160),
  const LatLng(52.202348, 0.131292),
  const LatLng(52.202336, 0.131436),
  const LatLng(52.202009, 0.132201),
  const LatLng(52.201979, 0.132249),
  const LatLng(52.201942, 0.132229),
  const LatLng(52.201211, 0.131636),
  const LatLng(52.201173, 0.131767),
  const LatLng(52.201908, 0.132382),
  const LatLng(52.201918, 0.132403),
  const LatLng(52.201912, 0.132438),
  const LatLng(52.201807, 0.132684),
  const LatLng(52.201541, 0.133349),
  const LatLng(52.201248, 0.134060),
  const LatLng(52.200975, 0.134719),
  const LatLng(52.200788, 0.135182),
  const LatLng(52.200604, 0.135630),
  const LatLng(52.200333, 0.136316),
  const LatLng(52.200166, 0.136762),
  const LatLng(52.200145, 0.136791),
  const LatLng(52.200122, 0.136778),
  const LatLng(52.199983, 0.136680),
  const LatLng(52.199951, 0.136812),
  const LatLng(52.200071, 0.136895),
  const LatLng(52.200089, 0.136921),
  const LatLng(52.200079, 0.136962),
  const LatLng(52.200009, 0.137128),
  const LatLng(52.199609, 0.138172),
  const LatLng(52.199587, 0.138195),
  const LatLng(52.199560, 0.138200),
  const LatLng(52.199386, 0.138093),
  const LatLng(52.199343, 0.138250),
  const LatLng(52.199502, 0.138348),
  const LatLng(52.199516, 0.138377),
  const LatLng(52.199511, 0.138414),
  const LatLng(52.199391, 0.138671),
  const LatLng(52.199177, 0.139262),
  const LatLng(52.199166, 0.139283),
  const LatLng(52.199145, 0.139276),
  const LatLng(52.198918, 0.139173),
  const LatLng(52.198898, 0.139271),
  const LatLng(52.199115, 0.139372),
  const LatLng(52.199130, 0.139392),
  const LatLng(52.199131, 0.139438),
  const LatLng(52.199057, 0.139679),
  const LatLng(52.198889, 0.140147),
  const LatLng(52.198726, 0.140688),
  const LatLng(52.198579, 0.141222),
  const LatLng(52.198304, 0.142080),
  const LatLng(52.198055, 0.142845),
  const LatLng(52.197961, 0.143170),
  const LatLng(52.197770, 0.143918),
  const LatLng(52.197739, 0.144027),
  const LatLng(52.197607, 0.144608),
  const LatLng(52.197521, 0.145009),
  const LatLng(52.197284, 0.145893),
  const LatLng(52.197186, 0.146266),
  const LatLng(52.197159, 0.146444),
  const LatLng(52.197136, 0.146976),
  const LatLng(52.197122, 0.148011),
  const LatLng(52.197103, 0.148069),
  const LatLng(52.197074, 0.148110),
  const LatLng(52.197048, 0.148144),
  const LatLng(52.197210, 0.148185),
  const LatLng(52.197223, 0.147414),
  const LatLng(52.197226, 0.146890),
  const LatLng(52.197269, 0.146475),
  const LatLng(52.197339, 0.146119),
  const LatLng(52.197391, 0.145883),
  const LatLng(52.197558, 0.145261),
  const LatLng(52.197579, 0.145217),
  const LatLng(52.197616, 0.145200),
  const LatLng(52.197971, 0.145428),
  const LatLng(52.198001, 0.145317),
  const LatLng(52.197646, 0.145094),
  const LatLng(52.197628, 0.145081),
  const LatLng(52.197625, 0.145054),
  const LatLng(52.197708, 0.144751),
  const LatLng(52.197832, 0.144268),
  const LatLng(52.197943, 0.143831),
  const LatLng(52.198035, 0.143470),
  const LatLng(52.198083, 0.143258),
  const LatLng(52.198104, 0.143208),
  const LatLng(52.198140, 0.143197),
  const LatLng(52.198236, 0.143244),
  const LatLng(52.198266, 0.143118),
  const LatLng(52.198177, 0.143080),
  const LatLng(52.198149, 0.143031),
  const LatLng(52.198138, 0.142983),
  const LatLng(52.198140, 0.142926),
  const LatLng(52.198382, 0.142151),
  const LatLng(52.198668, 0.141273),
  const LatLng(52.198895, 0.140431),
  const LatLng(52.198988, 0.140124),
  const LatLng(52.199095, 0.139858),
  const LatLng(52.199162, 0.139883),
  const LatLng(52.199606, 0.140096),
  const LatLng(52.199632, 0.139984),
  const LatLng(52.199209, 0.139779),
  const LatLng(52.199184, 0.139760),
  const LatLng(52.199179, 0.139726),
  const LatLng(52.199256, 0.139361),
  const LatLng(52.199383, 0.139018),
  const LatLng(52.199579, 0.138512),
  const LatLng(52.199598, 0.138483),
  const LatLng(52.199621, 0.138489),
  const LatLng(52.199890, 0.138613),
  const LatLng(52.199920, 0.138459),
  const LatLng(52.199704, 0.138368),
  const LatLng(52.199681, 0.138353),
  const LatLng(52.199688, 0.138300),
  const LatLng(52.199760, 0.138085),
  const LatLng(52.199945, 0.137636),
  const LatLng(52.200241, 0.136869),
  const LatLng(52.200441, 0.136359),
  const LatLng(52.200476, 0.136261),
  const LatLng(52.200601, 0.135953),
  const LatLng(52.200782, 0.135501),
  const LatLng(52.201060, 0.134820),
  const LatLng(52.201194, 0.134493),
  const LatLng(52.201365, 0.134080),
  const LatLng(52.201474, 0.133805),
  const LatLng(52.201700, 0.133240),
  const LatLng(52.201855, 0.132859),
  const LatLng(52.202082, 0.132347),
  const LatLng(52.202179, 0.132230),
  const LatLng(52.202263, 0.132047),
  const LatLng(52.202291, 0.131912),
  const LatLng(52.202413, 0.131640),
  const LatLng(52.202462, 0.131576),
  const LatLng(52.202535, 0.131529),
  const LatLng(52.202597, 0.131503),
  const LatLng(52.202644, 0.131375),
  const LatLng(52.202353, 0.131062),
];