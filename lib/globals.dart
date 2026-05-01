import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Consolidated global variables used across the app.
// Move only top-level variables here so other files can import a single source.

// Remember the previously selected bottom navigation index (used for back navigation).
int previousIndex = 0;

// App bar title shown on the HomePage.
String appBarTitle = 'Mill Road Winter Fair 2025';

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

// Prefix string used to mark cancelled events in listing descriptions. Must be at the very start of the description; anything else can follow
const String cancelIdentifier = 'CANCELLED';

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
