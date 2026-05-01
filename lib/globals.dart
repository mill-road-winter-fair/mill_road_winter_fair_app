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
