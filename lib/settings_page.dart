import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

// Define variable for first execution status
late bool firstExecution;

// Define available bearing of map display
enum MapOrientation { adaptive, alwaysNorth }

// Set default bearing of map display
late MapOrientation preferredMapOrientation;

// Define available map types
enum MapStyleType { normal, hybrid }

// Set default bearing of map display
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

// Initialise map style variable
late String mapStyle;

Future<void> loadSettings(bool onTest) async {
  if (onTest == false) {
    // Load settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Get first execution status, default to true
    firstExecution = prefs.getBool('firstExecution') ?? true;

    // Set default bearing display as Adaptive (0 in the index)
    int savedMapOrientationIndex = prefs.getInt('preferredMapOrientation') ?? 0;
    // Load preferred bearing display from shared preferences
    preferredMapOrientation = MapOrientation.values[savedMapOrientationIndex];

    // Set default bearing display as normal (0 in the index)
    int savedMapStyleTypeIndex = prefs.getInt('preferredMapStyleType') ?? 0;
    // Load preferred map type from shared preferences
    preferredMapStyleType = MapStyleType.values[savedMapStyleTypeIndex];

    // Set default sorting method as nearest (1 in the index)
    int savedSortingIndex = prefs.getInt('preferredSortingMethod') ?? 1;
    // Load preferred sorting method from shared preferences
    preferredSortingMethod = SortingMethod.values[savedSortingIndex];

    // Set default distance unit as metric (0 in the index)
    int savedUnitIndex = prefs.getInt('preferredDistanceUnits') ?? 0;
    // Load preferred distance unit from shared preferences
    preferredDistanceUnits = DistanceUnits.values[savedUnitIndex];

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
    int savedMapStyleTypeIndex = 0;
    preferredMapStyleType = MapStyleType.values[savedMapStyleTypeIndex];

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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          title: const Text('Metric'),
                          subtitle: Text(
                            'Metres & Kilometres',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                          value: DistanceUnits.metric,
                        ),
                        RadioListTile<DistanceUnits>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          title: const Text('Imperial'),
                          subtitle: Text(
                            'Feet & Miles',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                          value: DistanceUnits.imperial,
                        ),
                        RadioListTile<DistanceUnits>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          title: const Text('Cambridge'),
                          subtitle: Text(
                            'Punt lengths',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                          value: DistanceUnits.cambridge,
                        ),
                      ],
                    ),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      mapPageKey.currentState?.updateMarkerIconsForTheme();
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          title: const Text('Light'),
                          visualDensity: VisualDensity.compact,
                          value: 'light',
                        ),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          title: const Text('Dark'),
                          visualDensity: VisualDensity.compact,
                          value: 'dark',
                        ),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          title: const Text('2024 Colour Scheme'),
                          visualDensity: VisualDensity.compact,
                          value: '2024',
                        ),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          title: const Text('High Contrast'),
                          visualDensity: VisualDensity.compact,
                          value: 'highContrast',
                        ),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).colorScheme.tertiary,
                          title: const Text('Colour Blind Friendly'),
                          visualDensity: VisualDensity.compact,
                          value: 'colourBlindFriendly',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text('Onboarding', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ListTile(
                    leading: const Icon(Icons.first_page),
                    title: const Text('Replay Welcome Screen'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _replayWelcomeScreen(context);
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text('App Information', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showAboutDialog(
                          context: context, applicationName: 'Mill Road\nWinter Fair', applicationVersion: 'v 0.9.8', applicationIcon: const MyAppIcon());
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
