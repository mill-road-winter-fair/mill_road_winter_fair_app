import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

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

    int savedUnitIndex = prefs.getInt('preferredDistanceUnits') ?? 0; // Default to 0 (metric)
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
                  RadioListTile(
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    title: const Text('Metric'),
                    subtitle: Text(
                      'Metres & Kilometres',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    visualDensity: VisualDensity.compact,
                    value: DistanceUnits.metric,
                    groupValue: preferredDistanceUnits,
                    onChanged: (DistanceUnits? value) {
                      setState(() {
                        preferredDistanceUnits = value!;
                      });
                      _saveSettings();
                    },
                  ),
                  RadioListTile(
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    title: const Text('Imperial'),
                    subtitle: Text(
                      'Feet & Miles',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    visualDensity: VisualDensity.compact,
                    value: DistanceUnits.imperial,
                    groupValue: preferredDistanceUnits,
                    onChanged: (DistanceUnits? value) {
                      setState(() {
                        preferredDistanceUnits = value!;
                      });
                      _saveSettings();
                    },
                  ),
                  RadioListTile(
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    title: const Text('Cambridge'),
                    subtitle: Text(
                      'Punt lengths',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    visualDensity: VisualDensity.compact,
                    value: DistanceUnits.cambridge,
                    groupValue: preferredDistanceUnits,
                    onChanged: (DistanceUnits? value) {
                      setState(() {
                        preferredDistanceUnits = value!;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  RadioListTile(
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    title: const Text('Light'),
                    visualDensity: VisualDensity.compact,
                    value: 'light',
                    groupValue: themeNotifier.value,
                    onChanged: (value) {
                      selectedThemeKey = value!;
                      setState(() {
                        _changeTheme(value);
                        mapStyle = standardMap;
                      });
                      _saveSettings();
                      mapPageKey.currentState?.clearAllMarkers();
                      mapPageKey.currentState?.addAllMarkers(false);
                    },
                  ),
                  RadioListTile(
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    title: const Text('Dark'),
                    visualDensity: VisualDensity.compact,
                    value: 'dark',
                    groupValue: themeNotifier.value,
                    onChanged: (value) {
                      selectedThemeKey = value!;
                      setState(() {
                        _changeTheme(value);
                        mapStyle = darkMap;
                      });
                      _saveSettings();
                      mapPageKey.currentState?.clearAllMarkers();
                      mapPageKey.currentState?.addAllMarkers(false);
                    },
                  ),
                  RadioListTile(
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    title: const Text('2024 Colour Scheme'),
                    visualDensity: VisualDensity.compact,
                    value: '2024',
                    groupValue: themeNotifier.value,
                    onChanged: (value) {
                      setState(() {
                        _changeTheme(value!);
                        mapStyle = retroMap;
                      });
                      selectedThemeKey = value!;
                      _saveSettings();
                      mapPageKey.currentState?.clearAllMarkers();
                      mapPageKey.currentState?.addAllMarkers(false);
                    },
                  ),
                  RadioListTile(
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    title: const Text('High Contrast'),
                    visualDensity: VisualDensity.compact,
                    value: 'highContrast',
                    groupValue: themeNotifier.value,
                    onChanged: (value) {
                      setState(() {
                        _changeTheme(value!);
                        mapStyle = darkMap;
                      });
                      selectedThemeKey = value!;
                      _saveSettings();
                      mapPageKey.currentState?.clearAllMarkers();
                      mapPageKey.currentState?.addAllMarkers(false);
                    },
                  ),
                  RadioListTile(
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    title: const Text('Colour Blind Friendly'),
                    visualDensity: VisualDensity.compact,
                    value: 'colourBlindFriendly',
                    groupValue: themeNotifier.value,
                    onChanged: (value) {
                      selectedThemeKey = value!;
                      setState(() {
                        _changeTheme(value);
                        mapStyle = colourBlindMap;
                      });
                      _saveSettings();
                      mapPageKey.currentState?.clearAllMarkers();
                      mapPageKey.currentState?.addAllMarkers(false);
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
                      showAboutDialog(
                          context: context, applicationName: 'Mill Road\nWinter Fair', applicationVersion: 'v 0.9.6', applicationIcon: const MyAppIcon());
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
          'assets/icon.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
