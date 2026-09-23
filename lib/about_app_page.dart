import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'android_nav_bar_detector.dart';
import 'firebase_analytics.dart';
import 'globals.dart';

const _repositoryUrl =
    'https://github.com/mill-road-winter-fair/mill_road_winter_fair_app';

const _panelShadows = [
  BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2)),
];

ButtonStyle _aboutButtonStyle(BuildContext context) => TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.tertiary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: Alignment.centerLeft,
    );

class AboutAppPage extends StatefulWidget {
  final AnalyticsService analyticsService;

  const AboutAppPage({super.key, required this.analyticsService});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> with RouteAware {
  final _scrollController = ScrollController();
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 2),
      );
      if (mounted) setState(() => _packageInfo = info);
    } catch (error) {
      debugPrint('AboutAppPage: could not load app version: $error');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPush() => widget.analyticsService.setCurrentScreen('AboutAppPage');

  @override
  void didPopNext() => widget.analyticsService.setCurrentScreen('AboutAppPage');

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colours = theme.colorScheme;
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: Scaffold(
        backgroundColor: colours.surfaceDim,
        appBar: AppBar(
          leading: Navigator.canPop(context)
              ? BackButton(onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.analyticsService.logButtonTapped('back');
                  Navigator.maybePop(context);
                })
              : null,
          title: const Text('About this app'),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: !Platform.isIOS,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.bodyLarge!.copyWith(height: 1.55),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colours.primary,
                            boxShadow: _panelShadows,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset('assets/icons/icon.png',
                                    width: 64,
                                    height: 64,
                                    excludeFromSemantics: true),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                  'Made for the Fair.\nBuilt by our community.',
                                  style:
                                      theme.textTheme.headlineMedium!.copyWith(
                                    color: colours.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 12),
                              Text(
                                  'Your guide to Mill Road Winter Fair, brought to life by people who care about it.',
                                  style: TextStyle(color: colours.onPrimary)),
                              const SizedBox(height: 16),
                              Text(
                                  _packageInfo == null
                                      ? fairName
                                      : 'Version ${_packageInfo!.version} · Build ${_packageInfo!.buildNumber}',
                                  style: theme.textTheme.labelLarge!
                                      .copyWith(color: colours.onPrimary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _AboutSection(
                          icon: Icons.code,
                          title: 'A project we can build together',
                          children: [
                            Text(
                                'The Mill Road Winter Fair app is an open-source, community-driven project built with Flutter. It brings listings, maps, favourites and the timetable together to help you make the most of your day at the Fair.'),
                            Text(
                                'We welcome collaboration, whether you enjoy coding, have an eye for design, can help test the app or have an idea to share. To get involved, visit our GitHub repository and start with the CONTRIBUTING.md guide.'),
                            _AboutLink(
                                label: 'Read CONTRIBUTING.md',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'contributing_hyperlink',
                                url:
                                    'https://github.com/mill-road-winter-fair/mill_road_winter_fair_app/blob/main/CONTRIBUTING.md'),
                          ],
                        ),
                        _AboutSection(
                          icon: Icons.android,
                          title: 'Alexander Berridge',
                          subtitle: 'App Lead & founder',
                          children: [
                            Text(
                                'Alexander Berridge is an amateur coder whose day job is at the University of Cambridge’s School of Clinical Medicine. Alex founded the app and designed the backend caching layer, alongside other infrastructure that supports it.'),
                            Text(
                                'His work also includes Android development and maintaining the Android build configuration, helping turn the Fair’s information into a useful companion for visitors.'),
                            _AboutLink(
                                label: 'Visit Alex’s website',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'alex_website_hyperlink',
                                url: 'https://theberridge.com'),
                          ],
                        ),
                        _AboutSection(
                          icon: Icons.lightbulb_outline,
                          title: 'Matt Whiting',
                          subtitle: 'Contributor · Design, iOS & timetable',
                          children: [
                            Text(
                                'Matt Whiting is the retired former Chief Technology Officer of Cambridge Enterprise and has been working on the app for the past year. His excellent eye for design is behind many of the thoughtful interface details that make the app a pleasure to use, as well as his work on the iPhone version.'),
                            Text(
                                'The Fair is especially grateful for the timetable feature, based on code from Matt’s app, Clashfinder Pal. It helps festival-goers spot clashes between the acts they want to see and plan their day.'),
                            Text(
                                'Clashfinder Pal brings the Clashfinder website, created by fellow coder halvin, to mobile. Matt’s contribution brings that festival-planning experience to Mill Road.'),
                            _AboutLink(
                                label: 'Visit Matt’s website',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'matt_website_hyperlink',
                                url: 'http://mattwhiting.com'),
                            _AboutLink(
                                label: 'Discover Clashfinder Pal',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'clashfinder_pal_hyperlink',
                                url: 'https://linktr.ee/cfpal'),
                            _AboutLink(
                                label: 'Explore Clashfinder by halvin',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'clashfinder_hyperlink',
                                url: 'https://clashfinder.com'),
                          ],
                        ),
                        _AboutSection(
                          icon: Icons.palette_outlined,
                          title: 'Clare McEwan',
                          subtitle: 'Illustrations',
                          children: [
                            Text(
                                'The illustrations in the app are by Clare McEwan, a local Cambridge artist. Her drawings won the 2024 competition to provide artwork for the Fair’s promotional materials.'),
                            Text(
                                'Clare’s illustrations bring warmth, character and a distinctly local feel to the app, connecting it with the Fair’s printed materials and the community it celebrates.'),
                            _AboutLink(
                                label: 'Explore Clare’s artwork',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'clare_artwork_hyperlink',
                                url: 'https://www.claremcewan.co.uk'),
                          ],
                        ),
                        _AboutSection(
                          icon: Icons.layers_outlined,
                          title: 'The technology behind the app',
                          children: [
                            Text(
                                'Our community’s work is supported by these tools and services, alongside the open-source packages credited in the licences.'),
                            _Technology(
                                name: 'Flutter & Dart',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'flutter_hyperlink',
                                description:
                                    'The framework and language we use to build the app for Android and iOS from a shared codebase.',
                                url: 'https://flutter.dev'),
                            _Technology(
                                name: 'GitHub',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'github_hyperlink',
                                description:
                                    'Hosts our source code and gives contributors a place to report issues, discuss improvements and review changes.',
                                url: _repositoryUrl),
                            _Technology(
                                name: 'Heroku',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'heroku_hyperlink',
                                description:
                                    'Hosts the backend caching API, which fetches and caches listing information from Google Sheets for the app.',
                                url: 'https://www.heroku.com'),
                            _Technology(
                                name: 'Google Sheets',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'google_sheets_hyperlink',
                                description:
                                    'Stores the Fair’s listing information, which reaches the app through our caching API.',
                                url:
                                    'https://workspace.google.com/products/sheets/'),
                            _Technology(
                                name: 'Google Maps Platform',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'google_maps_platform_hyperlink',
                                description:
                                    'Provides the interactive map and walking directions to help visitors find their way around the Fair.',
                                url: 'https://mapsplatform.google.com'),
                            _Technology(
                                name: 'Shared Preferences',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'shared_preferences_hyperlink',
                                description:
                                    'Saves preferences and favourite listings on your device so they are available when you return.',
                                url:
                                    'https://pub.dev/packages/shared_preferences'),
                          ],
                        ),
                        _AboutSection(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy and Firebase Analytics',
                          children: [
                            Text(
                                'If you choose to share anonymous usage data, we use Firebase Analytics to understand which parts of the app are most useful and where they could be improved. This can include the pages and features you use, stalls and events you view or save, directions you request, words and phrases entered in searches, app preferences, and basic app, device and session information.'),
                            Text(
                                'Analytics is off unless you agree to it, and you can turn it off again in Settings. We do not use Firebase Analytics to collect your name, contact details or exact GPS location, or for personalised advertising.'),
                            _AboutLink(
                                label: 'Read our Privacy Policy',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'app_privacy_policy_link',
                                url:
                                    'https://www.millroadwinterfair.org/wp-content/uploads/2026/09/Mill-Road-Winter-Fair-App-Privacy-Policy.pdf'),
                          ],
                        ),
                        _AboutSection(
                          icon: Icons.gavel_outlined,
                          title: 'Terms of use',
                          children: [
                            Text(
                                'The terms explain the basis on which you may use the Mill Road Winter Fair app.'),
                            _AboutLink(
                                label: 'Read our Terms of Use',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'app_terms_of_use_link',
                                url:
                                    'https://www.millroadwinterfair.org/wp-content/uploads/2026/09/Mill-Road-Winter-Fair-App-Terms-of-Use.pdf'),
                          ],
                        ),
                        _AboutSection(
                          icon: Icons.feedback,
                          title: 'Help shape the next version',
                          children: [
                            const Text(
                                'We’d love to hear what works well, what could be better and what you’d like to see next. Your feedback helps us improve the app for everyone who comes to the Fair.'),
                            _AboutLink(
                                label: 'Share your feedback',
                                url:
                                    'https://www.millroadwinterfair.org/app-feedback-form/',
                                analyticsService: widget.analyticsService,
                                analyticsId: 'app_feedback_hyperlink'),
                            const Divider(),
                            const Text(
                                'With thanks to everyone who contributes code, artwork, ideas and time, and to the people who maintain the open-source software we use.'),
                            TextButton.icon(
                              style: _aboutButtonStyle(context),
                              icon: const Icon(Icons.description_outlined,
                                  size: 16),
                              label: const Text('View licences'),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                widget.analyticsService
                                    .logButtonTapped('view_licences');
                                showLicensePage(
                                  context: context,
                                  applicationName: fairName,
                                  applicationVersion: _packageInfo?.version,
                                );
                              },
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
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection(
      {required this.icon,
      required this.title,
      this.subtitle,
      required this.children});

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        boxShadow: _panelShadows,
        border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.tertiary, size: 28),
          const SizedBox(height: 12),
          Semantics(
              header: true,
              child: Text(title,
                  style: theme.textTheme.titleLarge!
                      .copyWith(fontWeight: FontWeight.bold))),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: theme.textTheme.labelLarge!
                    .copyWith(color: theme.colorScheme.tertiary)),
          ],
          for (final child in children) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }
}

class _Technology extends StatelessWidget {
  const _Technology(
      {required this.name,
      required this.description,
      required this.url,
      required this.analyticsService,
      required this.analyticsId});
  final String name;
  final String description;
  final String url;
  final AnalyticsService analyticsService;
  final String analyticsId;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutLink(
              label: name,
              url: url,
              analyticsService: analyticsService,
              analyticsId: analyticsId),
          Text(description),
        ],
      );
}

class _AboutLink extends StatelessWidget {
  const _AboutLink(
      {required this.label,
      required this.url,
      required this.analyticsService,
      required this.analyticsId});
  final String label;
  final String url;
  final AnalyticsService analyticsService;
  final String analyticsId;

  Future<void> _open(BuildContext context) async {
    HapticFeedback.lightImpact();
    analyticsService.logButtonTapped(analyticsId);
    try {
      if (await launchUrl(Uri.parse(url))) return;
    } catch (error) {
      debugPrint('AboutAppPage: could not open $url: $error');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Couldn’t open this link. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = Text(label);
    return Semantics(
      link: true,
      child: TextButton.icon(
        style: _aboutButtonStyle(context),
        onPressed: () => _open(context),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: child,
      ),
    );
  }
}
