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
