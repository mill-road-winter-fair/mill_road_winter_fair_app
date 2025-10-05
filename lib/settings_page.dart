import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

// Define variable for first execution status
late bool firstExecution;

// Define available sorting methods
enum SortingMethod { alphabetical, nearest, startTime, location }

// Define variable for sorting method
late SortingMethod preferredSortingMethod;

// Define available distance units
enum DistanceUnits { metric, imperial, cambridge }

// Set default distance units
late DistanceUnits preferredDistanceUnits;

// Define available bearing of map display
enum MapOrientation { adaptive, alwaysNorth }

// Set default bearing of map display
late MapOrientation preferredMapOrientation;

// Initialise theme variables
late String selectedThemeKey;
late ValueNotifier<String> themeNotifier;

// Initialise map style variable
late String mapStyle;

Future<void> loadSettings(bool onTest) async {
  if (onTest == false) {
    // Load settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Get first execution status, default to true
    firstExecution = prefs.getBool('firstExecution') ?? true;

    // Set default sorting method as nearest (1 in the index)
    int savedSortingIndex = prefs.getInt('preferredSortingMethod') ?? 1;
    // Load preferred sorting method from shared preferences
    preferredSortingMethod = SortingMethod.values[savedSortingIndex];

    // Set default distance unit as metric (0 in the index)
    int savedUnitIndex = prefs.getInt('preferredDistanceUnits') ?? 0;
    // Load preferred distance unit from shared preferences
    preferredDistanceUnits = DistanceUnits.values[savedUnitIndex];

    // Set default bearing display as Adaptive (0 in the index)
    int savedMapOrientationIndex = prefs.getInt('preferredMapOrientation') ?? 0;
    // Load preferred bearing display from shared preferences
    preferredMapOrientation = MapOrientation.values[savedMapOrientationIndex];

    // Detect system brightness
    Brightness systemBrightness = PlatformDispatcher.instance.platformBrightness;

    // Set initial theme and map style according to system brightness
    String defaultTheme = systemBrightness == Brightness.light ? 'light' : 'dark';
    String defaultMapStyle = systemBrightness == Brightness.dark ? darkMap : standardMap;
    selectedThemeKey = prefs.getString('selectedTheme') ?? defaultTheme;
    mapStyle = prefs.getString('selectedMapStyle') ?? defaultMapStyle;

    // Create a ValueNotifier to hold the current theme
    themeNotifier = ValueNotifier(selectedThemeKey);
  } else if (onTest == true) {
    int savedUnitIndex = 0;
    preferredDistanceUnits = DistanceUnits.values[savedUnitIndex];
    int savedSortingIndex = 1;
    preferredSortingMethod = SortingMethod.values[savedSortingIndex];
    int savedMapOrientationIndex = 0;
    preferredMapOrientation = MapOrientation.values[savedMapOrientationIndex];

    selectedThemeKey = 'light';
    // Create a ValueNotifier to hold the current theme
    themeNotifier = ValueNotifier(selectedThemeKey);

    mapStyle = 'standardMap';
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredDistanceUnits', preferredDistanceUnits.index);
    await prefs.setInt('preferredMapOrientation', preferredMapOrientation.index);
    await prefs.setString('selectedTheme', themeNotifier.value);
    await prefs.setString('selectedMapStyle', mapStyle);
  }

  Future<void> _changeTheme(String themeKey) async {
    themeNotifier.value = themeKey;
  }

  // Function to replay the initial welcome screen
  void _replayWelcomeScreen(context) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 10.0, 0.0),
        margin: const EdgeInsets.fromLTRB(6.0, 2.0, 0.0, 0.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 0.0,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 0.0,
                children: [
                  const Text('Distance Units', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  RadioGroup<DistanceUnits>(
                    groupValue: preferredDistanceUnits,
                    onChanged: (DistanceUnits? value) {
                      setState(() {
                        HapticFeedback.selectionClick();
                        preferredDistanceUnits = value!;
                      });
                      _saveSettings();
                    },
                    child: Column(
                      children: [
                        RadioListTile<DistanceUnits>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('Metric'),
                          subtitle: Text(
                            'Metres & Kilometres',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          visualDensity:
                              VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: DistanceUnits.metric,
                        ),
                        RadioListTile<DistanceUnits>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('Imperial'),
                          subtitle: Text(
                            'Feet & Miles',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          visualDensity:
                              VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: DistanceUnits.imperial,
                        ),
                        RadioListTile<DistanceUnits>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('Cambridge'),
                          subtitle: Text(
                            'Punt lengths',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: DistanceUnits.cambridge,
                        ),
                      ],
                    ),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 0.0,
                children: [
                  const Text('Map Orientation',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  RadioGroup<MapOrientation>(
                    groupValue: preferredMapOrientation,
                    onChanged: (MapOrientation? value) {
                      setState(() {
                        HapticFeedback.selectionClick();
                        preferredMapOrientation = value!;
                      });
                      _saveSettings();
                    },
                    child: Column(
                      children: [
                        RadioListTile<MapOrientation>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('Adaptive'),
                          subtitle: Text(
                            'Rotates the map to fit best on screen',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: MapOrientation.adaptive,
                        ),
                        RadioListTile<MapOrientation>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('North South'),
                          subtitle: Text(
                            'Always shows North at the top of the map',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: MapOrientation.alwaysNorth,
                        ),
                      ],
                    ),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 0.0,
                children: [
                  const Text('Theme', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  RadioGroup<String>(
                    groupValue: themeNotifier.value,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      selectedThemeKey = value!;
                      setState(() {
                        _changeTheme(value);
                        switch (value) {
                          case 'light':
                            mapStyle = standardMap;
                            break;
                          case 'dark':
                            mapStyle = darkMap;
                            break;
                          case '2024':
                            mapStyle = retroMap;
                            break;
                          case 'highContrast':
                            mapStyle = darkMap;
                            break;
                          case 'colourBlindFriendly':
                            mapStyle = colourBlindMap;
                            break;
                        }
                      });
                      _saveSettings();
                      mapPageKey.currentState?.clearAllMarkers();
                      mapPageKey.currentState?.addAllVisibleMarkers(false);
                    },
                    child: Column(
                      spacing: 0.0,
                      children: [
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('Light'),
                          visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: 'light',
                        ),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('Dark'),
                          visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: 'dark',
                        ),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('2024 Colour Scheme'),
                          visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: '2024',
                        ),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('High Contrast'),
                          visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: 'highContrast',
                        ),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: const Text('Colour Blind Friendly'),
                          visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                          value: 'colourBlindFriendly',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 0.0,
                children: [
                  const SizedBox(height: 10),
                  const Text('App Info and Onboarding', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ListTile(
                    leading: const Icon(Icons.first_page),
                    title: const Text('Replay Welcome Screen'),
                    visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _replayWelcomeScreen(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About This App'), visualDensity: VisualDensity(horizontal: 0.0, vertical: -4.0),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showAboutDialog(
                          context: context,
                          applicationName: 'Mill Road\nWinter Fair',
                          applicationVersion: 'v 0.9.7',
                          applicationIcon: const MyAppIcon());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyAppIcon extends StatelessWidget {
  const MyAppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.asset(
          'assets/icons/icon.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
