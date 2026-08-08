import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';

class AnalyticsExplanationPage extends StatefulWidget {
  final AnalyticsService analyticsService;

  const AnalyticsExplanationPage({super.key, required this.analyticsService});

  @override
  State<AnalyticsExplanationPage> createState() => _AnalyticsExplanationPageState();
}

class _AnalyticsExplanationPageState extends State<AnalyticsExplanationPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.analyticsService.setCurrentScreen('AnalyticsExplanationPage');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            child: Text('Analytics Information'),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: Platform.isIOS ? false : true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SingleChildScrollView(
                controller: _scrollController,
                primary: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What is Firebase?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Firebase',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(Uri.parse('https://firebase.google.com/'));
                                widget.analyticsService.logButtonTapped('firebase_info_link');
                              },
                          ),
                          const TextSpan(
                            text:
                                ' is a platform provided by Google that helps app developers build, improve, and grow their apps. Firebase Analytics is a specific part of this platform that helps us understand how people use our app by collecting anonymous data such as which screens are visited and which features are most popular.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'What are we using it for?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We use this anonymous data to:',
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Understand which parts of the app are most useful to Fair attendees.'),
                          SizedBox(height: 4),
                          Text('• Identify any issues or areas where the app could be improved.'),
                          SizedBox(height: 4),
                          Text('• Help us plan for future Fairs by understanding which stalls and events are most viewed.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'How does Google use this data?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(
                            text:
                                'Google uses the data collected through Firebase to provide and improve its services. This includes troubleshooting, data analysis, and ensuring the security of the platform. You can find more detailed information on how Google uses information from sites or apps that use their services ',
                          ),
                          TextSpan(
                            text: 'here',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(Uri.parse('https://policies.google.com/technologies/partner-sites'));
                                widget.analyticsService.logButtonTapped('google_partner_sites_link');
                              },
                          ),
                          const TextSpan(text: ' and in the '),
                          TextSpan(
                            text: 'Firebase Privacy and Security documentation',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(Uri.parse('https://firebase.google.com/support/privacy'));
                                widget.analyticsService.logButtonTapped('firebase_privacy_link');
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Crucially, no personal information is collected by us or shared with Google through this app. We cannot identify you personally from this data; we don\'t collect names, email addresses, or your exact location.',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

class AnalyticsExplanationPagePreview extends StatelessWidget {
  const AnalyticsExplanationPagePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return AnalyticsExplanationPage(analyticsService: FakeAnalyticsService());
  }
}
