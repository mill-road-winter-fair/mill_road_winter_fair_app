import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

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

Future<void> loadSettings() async {
  debugPrint('loadSettings called, onTest=$onTest');
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

    // Set default road closure polygon as visible
    preferredRoadClosurePolygonVisible = prefs.getBool('preferredRoadClosurePolygonVisible') ?? true;
    
    // Set default sorting method as nearest (1 in the index)
    int savedSortingIndex = prefs.getInt('preferredSortingMethod') ?? 1;
    // Load preferred sorting method from shared preferences
    preferredSortingMethod = SortingMethod.values[savedSortingIndex];

    // Set default distance unit as metric (0 in the index)
    int savedUnitIndex = prefs.getInt('preferredDistanceUnits') ?? 0;
    // Load preferred distance unit from shared preferences
    preferredDistanceUnits = DistanceUnits.values[savedUnitIndex];

    // Get the list of favourited listings
    final favouriteListingStrings = prefs.getStringList('favouritesList');
    if (favouriteListingStrings != null) {
      favouriteListingKeys = favouriteListingStrings.toSet();
    } else {
      favouriteListingKeys = {};
    }

    // Detect system brightness
    Brightness systemBrightness = PlatformDispatcher.instance.platformBrightness;

    // Set initial theme and map style according to system brightness
    String defaultTheme = systemBrightness == Brightness.light ? 'light' : 'dark';
    String defaultMapStyle = systemBrightness == Brightness.dark ? darkMap : standardMap;
    selectedThemeKey = prefs.getString('selectedTheme') ?? defaultTheme;
    mapStyle = prefs.getString('selectedMapStyle') ?? defaultMapStyle;

    // We're currently storing the mapStyle as a string in SharedPreferences
    // If we update the mapStyles at any point the user will not get the updated styles unless they change theme
    // To get around this, whenever we load the settings we re-apply the map style
    switch (selectedThemeKey) {
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

    // Create a ValueNotifier to hold the current theme
    themeNotifier = ValueNotifier(selectedThemeKey);

    debugPrint('Settings loaded from SharedPreferences');
  } else if (onTest == true) {
    int savedUnitIndex = 0;
    preferredDistanceUnits = DistanceUnits.values[savedUnitIndex];
    int savedSortingIndex = 1;
    preferredSortingMethod = SortingMethod.values[savedSortingIndex];
    int savedMapOrientationIndex = 0;
    preferredMapOrientation = MapOrientation.values[savedMapOrientationIndex];
    int savedMapStyleTypeIndex = 0;
    preferredMapStyleType = MapStyleType.values[savedMapStyleTypeIndex];
    preferredRoadClosurePolygonVisible = true;

    selectedThemeKey = 'light';
    // Create a ValueNotifier to hold the current theme
    themeNotifier = ValueNotifier(selectedThemeKey);

    mapStyle = standardMap;
    favouriteListingKeys = {};

  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Scroll controller for the page's scrollable content so we can attach a visible scrollbar
  late ScrollController _settingsPageScrollController;

  @override
  void initState() {
    super.initState();
    _settingsPageScrollController = ScrollController();
  }

  @override
  void dispose() {
    _settingsPageScrollController.dispose();
    super.dispose();
  }

// Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredDistanceUnits', preferredDistanceUnits.index);
    await prefs.setString('selectedTheme', themeNotifier.value);
    await prefs.setString('selectedMapStyle', mapStyle);
    await prefs.setBool('preferredRoadClosurePolygonVisible', preferredRoadClosurePolygonVisible);
    await prefs.setStringList('favouritesList', favouriteListingKeys.toList());
  }

  Future<void> _changeTheme(String themeKey) async {
    themeNotifier.value = themeKey;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: Scaffold(
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Settings'),
          ),
        ),
        body: Container(
          padding: EdgeInsets.all(10.0 + ((MediaQuery.of(context).size.height.toInt() - 500) / 50).toInt()),
          child: Scrollbar(
            controller: _settingsPageScrollController,
            thumbVisibility: Platform.isIOS ? false : true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SingleChildScrollView(
                controller: _settingsPageScrollController,
                primary: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Distance units', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                                  'Metres and kilometres',
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
                                  'Feet and miles',
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
                            mapPageKey.currentState?.updateMarkersAndPolygonsForTheme();
                          },
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                activeColor: Theme.of(context).colorScheme.tertiary,
                                title: const Text('Light'),
                                subtitle: Text(
                                  'The default for devices set to light mode',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                                value: 'light',
                              ),
                              RadioListTile<String>(
                                activeColor: Theme.of(context).colorScheme.tertiary,
                                title: const Text('Dark'),
                                subtitle: Text(
                                  'The default for devices set to dark mode',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                                value: 'dark',
                              ),
                              RadioListTile<String>(
                                activeColor: Theme.of(context).colorScheme.tertiary,
                                title: const Text('2024 colour scheme'),
                                subtitle: Text(
                                  'For the Fair that blew away',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                                value: '2024',
                              ),
                              RadioListTile<String>(
                                activeColor: Theme.of(context).colorScheme.tertiary,
                                title: const Text('High contrast'),
                                subtitle: Text(
                                    'For users with visual accessibility needs',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                visualDensity: VisualDensity.compact,
                                value: 'highContrast',
                              ),
                              RadioListTile<String>(
                                activeColor: Theme.of(context).colorScheme.tertiary,
                                title: const Text('Colour blind friendly'),
                                subtitle: Text(
                                  'For users with colour blindness',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                                value: 'colourBlindFriendly',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
