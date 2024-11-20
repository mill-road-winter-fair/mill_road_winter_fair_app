import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define available distance units
enum DistanceUnits { metric, imperial }

// Set default distance units
DistanceUnits preferredDistanceUnits = DistanceUnits.metric;

// Initialise theme variables
late String selectedThemeKey; // Currently selected theme key
late ThemeData selectedTheme; // Currently selected theme
late ValueNotifier<String> themeNotifier;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredDistanceUnits', preferredDistanceUnits.index);
    await prefs.setString('selectedTheme', themeNotifier.value);
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
        child: Column(
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
                    });
                    _saveSettings();
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
                    });
                    _saveSettings();
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
                    });
                    selectedThemeKey = value!;
                    _saveSettings();
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
                    });
                    selectedThemeKey = value!;
                    _saveSettings();
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
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
