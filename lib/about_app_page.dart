import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'android_nav_bar_detector.dart';
import 'globals.dart';

const _repositoryUrl =
    'https://github.com/mill-road-winter-fair/mill_road_winter_fair_app';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
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
  void dispose() {
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
        appBar: AppBar(title: const Text('About this app')),
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
                        const _AboutSection(
                          icon: Icons.code,
                          title: 'A project we can build together',
                          children: [
                            Text(
                                'The Mill Road Winter Fair app is an open-source, community-driven project built with Flutter. It brings listings, maps, favourites and the timetable together to help you make the most of your day at the Fair.'),
                            Text(
                                'We welcome collaboration, whether you enjoy coding, have an eye for design, can help test the app or have an idea to share. To get involved, visit our GitHub repository and start with the CONTRIBUTING.md guide.'),
                            _AboutLink(
                                label: 'Read CONTRIBUTING.md',
                                url:
                                    'https://github.com/mill-road-winter-fair/mill_road_winter_fair_app/blob/main/CONTRIBUTING.md'),
                          ],
                        ),
                        const _AboutSection(
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
                                url: 'https://theberridge.com'),
                          ],
                        ),
                        const _AboutSection(
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
                                url: 'http://mattwhiting.com'),
                            _AboutLink(
                                label: 'Discover Clashfinder Pal',
                                url: 'https://linktr.ee/cfpal'),
                            _AboutLink(
                                label: 'Explore Clashfinder by halvin',
                                url: 'https://clashfinder.com'),
                          ],
                        ),
                        const _AboutSection(
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
                                url: 'https://www.claremcewan.co.uk'),
                          ],
                        ),
                        const _AboutSection(
                          icon: Icons.layers_outlined,
                          title: 'The technology behind the app',
                          children: [
                            Text(
                                'Our community’s work is supported by these tools and services, alongside the open-source packages credited in the licences.'),
                            _Technology(
                                name: 'Flutter & Dart',
                                description:
                                    'The framework and language we use to build the app for Android and iOS from a shared codebase.',
                                url: 'https://flutter.dev'),
                            _Technology(
                                name: 'GitHub',
                                description:
                                    'Hosts our source code and gives contributors a place to report issues, discuss improvements and review changes.',
                                url: _repositoryUrl),
                            _Technology(
                                name: 'Heroku',
                                description:
                                    'Hosts the backend caching API, which fetches and caches listing information from Google Sheets for the app.',
                                url: 'https://www.heroku.com'),
                            _Technology(
                                name: 'Google Sheets',
                                description:
                                    'Stores the Fair’s listing information, which reaches the app through our caching API.',
                                url:
                                    'https://workspace.google.com/products/sheets/'),
                            _Technology(
                                name: 'Google Maps Platform',
                                description:
                                    'Provides the interactive map and walking directions to help visitors find their way around the Fair.',
                                url: 'https://mapsplatform.google.com'),
                            _Technology(
                                name: 'Shared Preferences',
                                description:
                                    'Saves preferences and favourite listings on your device so they are available when you return.',
                                url:
                                    'https://pub.dev/packages/shared_preferences'),
                          ],
                        ),
                        _AboutSection(
                          icon: Icons.feedback,
                          title: 'Help shape the next version',
                          children: [
                            const Text(
                                'We’d love to hear what works well, what could be better and what you’d like to see next. Your feedback helps us improve the app for everyone who comes to the Fair.'),
                            const _AboutLink(
                                label: 'Share your feedback',
                                url:
                                    'https://www.millroadwinterfair.org/app-feedback-form/',
                                prominent: true),
                            const Divider(),
                            const Text(
                                'With thanks to everyone who contributes code, artwork, ideas and time, and to the people who maintain the open-source software we use.'),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.description_outlined),
                              label: const Text('View licences'),
                              onPressed: () {
                                HapticFeedback.lightImpact();
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
      {required this.name, required this.description, required this.url});
  final String name;
  final String description;
  final String url;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutLink(label: name, url: url),
          Text(description),
        ],
      );
}

class _AboutLink extends StatelessWidget {
  const _AboutLink(
      {required this.label, required this.url, this.prominent = false});
  final String label;
  final String url;
  final bool prominent;

  Future<void> _open(BuildContext context) async {
    HapticFeedback.lightImpact();
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
      child: prominent
          ? FilledButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: child)
          : TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.tertiary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                alignment: Alignment.centerLeft,
              ),
              onPressed: () => _open(context),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: child,
            ),
    );
  }
}
