import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/analytics_explanation_page.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadSettings() async {
  debugPrint('loadSettings called, onTest=$onTest');
  if (onTest == false) {
    // Load settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Get analytics preference status
    usageAnalyticsEnabled = prefs.getBool('usageAnalyticsEnabled');

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

    // Keep the listings-change notice enabled by default for each fair year.
    listingUpdateNoticeEnabled = prefs.getBool(
          'listingUpdateNoticeEnabled${fairDate.year}',
        ) ??
        true;

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
      favouriteListingKeys.value = favouriteListingStrings.toSet();
    } else {
      favouriteListingKeys.value = {};
    }

    // Set initial theme and map style to change according to system brightness
    String defaultTheme = 'auto';
    selectedThemeKey = prefs.getString('selectedTheme') ?? defaultTheme;
    if (!appThemes.containsKey(selectedThemeKey) && selectedThemeKey != 'auto') selectedThemeKey = defaultTheme;
    mapStyle = getMapStyleForThemeKey(selectedThemeKey);

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
    listingUpdateNoticeEnabled = true;

    selectedThemeKey = 'light';
    // Create a ValueNotifier to hold the current theme
    themeNotifier = ValueNotifier(selectedThemeKey);

    mapStyle = standardMap;
    favouriteListingKeys.value = {};

  }
}

class SettingsPage extends StatefulWidget {
  final AnalyticsService analyticsService;

  const SettingsPage({super.key, required this.analyticsService});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with RouteAware {
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
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routeObserver.subscribe(
      this,
      ModalRoute.of(context)!,
    );
  }

  @override
  void didPush() {
    widget.analyticsService.setCurrentScreen('SettingsPage');
  }

  @override
  void didPopNext() {
    widget.analyticsService.setCurrentScreen('SettingsPage');
  }

// Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredDistanceUnits', preferredDistanceUnits.index);
    if (usageAnalyticsEnabled != null) {
      await prefs.setBool('usageAnalyticsEnabled', usageAnalyticsEnabled!);
    }
    await prefs.setString('selectedTheme', themeNotifier.value);
    await prefs.setString('selectedMapStyle', mapStyle);
    await prefs.setBool('preferredRoadClosurePolygonVisible', preferredRoadClosurePolygonVisible);
    await prefs.setBool(
      'listingUpdateNoticeEnabled${fairDate.year}',
      listingUpdateNoticeEnabled,
    );
    await prefs.setStringList('favouritesList', favouriteListingKeys.value.toList());
  }

  Future<void> _changeTheme(String themeKey) async {
    themeNotifier.value = themeKey;
  }

  @override
  Widget build(BuildContext context) {
    final settingLabelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    final settingTitleStyle = TextStyle(fontSize: 15);
    final settingSubtitleStyle = TextStyle(fontSize: 14,  color: Theme.of(context).colorScheme.onSurfaceVariant);
    final List<DropdownOption> unitsOptions = [
      DropdownOption(title: 'Metric', subtitle: 'Metres and kilometres', value: DistanceUnits.metric),
      DropdownOption(title: 'Imperial', subtitle: 'Feet and miles', value: DistanceUnits.imperial),
      DropdownOption(title: 'Cambridge', subtitle: 'Punt lengths', value: DistanceUnits.cambridge)
    ];
    final List<DropdownOption> themeOptions = [
      DropdownOption(title: 'Auto', subtitle: 'Follow the device light/dark setting', value: 'auto'),
      DropdownOption(title: 'Light', subtitle: 'A bright theme using white pages', value: 'light'),
      DropdownOption(title: 'Dark', subtitle: 'A subdued theme using black pages', value: 'dark'),
      DropdownOption(title: '2025 Light', subtitle: 'For last year’s Fair', value: '2025'),
      DropdownOption(title: '2024 Light', subtitle: 'For the Fair that blew away', value: '2024'),
      DropdownOption(title: 'High contrast', subtitle: 'For visual accessibility needs', value: 'highContrast'),
      DropdownOption(title: 'Colour blind friendly', subtitle: 'For users with colour blindness', value: 'colourBlindFriendly')
    ];
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: Scaffold(
        appBar: AppBar(
          leading: Navigator.canPop(context) ? BackButton(onPressed: () {
            HapticFeedback.lightImpact();
            widget.analyticsService.logButtonTapped('back');
            Navigator.maybePop(context);
          }) : null,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(spacing: 12, children: [
                      Text('Theme:', style: settingLabelStyle),
                      Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                          return DropdownButton<String>(
                            menuWidth: constraints.maxWidth,
                            value: themeNotifier.value,
                            isExpanded: true,
                            hint: const Text('Select a visual theme'),
                            selectedItemBuilder: (context) {
                              return themeOptions.map((opt) {
                                return Container(alignment: Alignment.centerLeft, height: 56, child: Text(opt.title));
                              }).toList();
                            },
                            items: themeOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt.value,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(opt.title, style: settingTitleStyle),
                                    Text(opt.subtitle, style: settingSubtitleStyle),
                                    SizedBox(height: 4),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              widget.analyticsService.logButtonTapped('theme_preference_option');
                              if (value == null) return;
                              widget.analyticsService.logThemePreferenceSet(value);
                              selectedThemeKey = value;
                              setState(() {
                                _changeTheme(value);
                                mapStyle = getMapStyleForThemeKey(value);
                              });
                              _saveSettings();
                              mapPageKey.currentState?.updateMarkersAndPolygonsForTheme();
                            },
                          );
                        })
                      ),
                    ]),
                    Divider(),
                    Row(spacing: 12, children: [
                      Text('Distances:', style: settingLabelStyle),
                      Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                          return DropdownButton<DistanceUnits>(
                            menuWidth: constraints.maxWidth,
                            value: preferredDistanceUnits,
                            isExpanded: true,
                            hint: const Text('Select units for map distances'),
                            selectedItemBuilder: (context) {
                              return unitsOptions.map((opt) {
                                return Container(
                                  alignment: Alignment.centerLeft, 
                                  child: Text(opt.title));
                              }).toList();
                            },
                            items: unitsOptions.map((opt) {
                              return DropdownMenuItem<DistanceUnits>(
                                value: opt.value,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(opt.title, style: settingTitleStyle),
                                    Text(opt.subtitle, style: settingSubtitleStyle),
                                    SizedBox(height: 4),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (DistanceUnits? value) {
                              if (value == null) return;
                              HapticFeedback.selectionClick();
                              widget.analyticsService.logButtonTapped('distanceUnit_preference_option');
                              widget.analyticsService.logDistanceUnitPreferenceSet(value.name);
                              setState(() {
                                preferredDistanceUnits = value;
                              });
                              _saveSettings();
                            },
                          );
                        }),
                      ),
                    ]),
                    Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: Theme.of(context).colorScheme.tertiary,
                      title: Text('Allow analytics', style: settingLabelStyle),
                      subtitle: Text.rich(
                        TextSpan(children: [
                        TextSpan(text: 'Help us improve the app and the Fair by sharing anonymous usage data with us and Google. '),
                        TextSpan(
                          text: 'What does this mean?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              HapticFeedback.lightImpact();
                              widget.analyticsService.logButtonTapped('analytics_explanation_settings');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnalyticsExplanationPage(analyticsService: widget.analyticsService),
                                ),
                              );
                            },
                        ),
                        ]),
                      ),
                      value: usageAnalyticsEnabled ?? false,
                      onChanged: (bool value) async {
                        HapticFeedback.selectionClick();
                        widget.analyticsService.logButtonTapped('analytics_preference_toggle');
                        await widget.analyticsService.setAnalyticsEnabled(value);
                        if (mounted) setState(() {});
                      },
                    ),
                    Divider(),
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

class DropdownOption {
  final String title;
  final String subtitle;
  final dynamic value;
  DropdownOption({
    required this.title,
    required this.subtitle,
    required this.value,
  });
}