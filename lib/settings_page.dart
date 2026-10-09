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

    // Get the choice to have a static chooser page
    staticChooserPage.value = prefs.getBool('staticChooserPage') ?? false;

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
    await prefs.setBool('staticChooserPage', staticChooserPage.value);
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
    final List<DropdownOption> homePageOptions = [
      DropdownOption(title: 'Animated', subtitle: 'Spotlights the Fair’s offerings', value: false),
      DropdownOption(title: 'Static', subtitle: 'Stays boringly fixed', value: true),
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
            child: SingleChildScrollView(
              controller: _settingsPageScrollController,
              primary: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(spacing: 12, children: [
                    Text('Theme:', style: settingLabelStyle),
                    Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                        return DropdownMenu<String>(
                          initialSelection: themeNotifier.value,
                          hintText: 'Select a visual theme',
                          inputDecorationTheme: InputDecorationTheme(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                          alignmentOffset: const Offset(0, -60),
                          expandedInsets: EdgeInsets.zero,
                          trailingIcon: Icon(Icons.arrow_drop_down, size: 30),
                          dropdownMenuEntries: themeOptions.map((opt) {
                            return DropdownMenuEntry<String>(
                              value: opt.value,
                              label: opt.title,
                              labelWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const SizedBox(height: 4),
                                Text(opt.title, style: settingTitleStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                                Text(opt.subtitle, style: settingSubtitleStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                              ]),
                            );
                          }).toList(),
                          onSelected: (value) {
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
                          },
                        );
                      })
                    ),
                  ]),
                  Row(spacing: 12, children: [
                    Text('Distances:', style: settingLabelStyle),
                    Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                        return DropdownMenu<DistanceUnits>(
                          initialSelection: preferredDistanceUnits,
                          hintText: 'Select units for map distances',
                          inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                          alignmentOffset: const Offset(0, -60),
                          expandedInsets: EdgeInsets.zero,
                          trailingIcon: Icon(Icons.arrow_drop_down, size: 30),
                          dropdownMenuEntries: unitsOptions.map((opt) {
                            return DropdownMenuEntry<DistanceUnits>(
                              value: opt.value,
                              label: opt.title,
                              labelWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const SizedBox(height: 4),
                                Text(opt.title, style: settingTitleStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                                Text(opt.subtitle, style: settingSubtitleStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                              ]),
                            );
                          }).toList(),
                          onSelected: (DistanceUnits? value) {
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
                  Row(spacing: 12, children: [
                    Text('Home page:', style: settingLabelStyle),
                    Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                        return DropdownMenu<bool>(
                          initialSelection: staticChooserPage.value,
                          hintText: 'Select style of home page',
                          inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                          alignmentOffset: const Offset(0, -60),
                          expandedInsets: EdgeInsets.zero,
                          trailingIcon: Icon(Icons.arrow_drop_down, size: 30),
                          dropdownMenuEntries: homePageOptions.map((opt) {
                            return DropdownMenuEntry<bool>(
                              value: opt.value,
                              label: opt.title,
                              labelWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const SizedBox(height: 4),
                                Text(opt.title, style: settingTitleStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                                Text(opt.subtitle, style: settingSubtitleStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                              ]),
                            );
                          }).toList(),
                          onSelected: (bool? value) {
                            setState(() {
                              HapticFeedback.selectionClick();
                              staticChooserPage.value = value!;
                            });
                            _saveSettings();
                          },
                        );
                      }),
                    ),
                  ]),
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
                ],
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