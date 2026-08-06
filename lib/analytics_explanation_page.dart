import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';

class AnalyticsExplanationPage extends StatelessWidget {
  final AnalyticsService analyticsService;

  const AnalyticsExplanationPage({super.key, required this.analyticsService});

  @override
  Widget build(BuildContext context) {
    analyticsService.setCurrentScreen('AnalyticsExplanationPage');

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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What is Firebase Analytics?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Firebase Analytics is a tool provided by Google that helps app developers understand how people use their apps. It collects anonymous data such as which screens are visited, which buttons are tapped, and which features are most popular.',
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
              const Text(
                'Crucially, no personal information is collected. We cannot identify you personally from this data; we don\'t collect names, email addresses, or your exact location.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
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
