import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/main.dart';

class AboutTheFairPage extends StatelessWidget {
  const AboutTheFairPage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('AboutTheFairPage build() called');
    var bodyStyle = TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary);
    return Scaffold(
      appBar: AppBar(title: const Text("About Mill Road Winter Fair")),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text("Mill Road Winter Fair is a celebration of community along one of the most diverse and vibrant roads in Cambridge. Usually held on the first Saturday of December, the Fair brings together local businesses and organisations, shops and stallholders, musicians, artists and dancers in one day of festival joy."),
              const SizedBox(height: 12),
              Text('The 2025 Fair will be on Saturday 6th December, 10.30am to 4.30pm.', style: bodyStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Be sure to come early so that you don’t miss out; we have so much to see! The fire engine pull, opening ceremony, dance show and parade are all in the morning, as well as lots of amazing stalls, performance and events.', style: bodyStyle),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'There are lots of opportunities to volunteer for the Fair – from communications, finding performers, setting stuff up, stewarding and just plain old organising – so do '),
                    TextSpan(
                        text: 'get in touch',
                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            HapticFeedback.lightImpact();
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => emailDetailsDialog(),
                            );
                          }),
                    const TextSpan(text: ' if you’d like to be involved, or if you have a questions or ideas about the Fair.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('We also have a number of Fringe events throughout the year, with which we’d love you to get involved.', style: bodyStyle),
              const SizedBox(height: 12),
              Text('We are grateful for the support of our generous sponsors: Bush & Co Sales and Lettings (lead sponsor), Anglia Ruskin University,  Hughes Hall, Taank Optometrists,  Regalstar catering and Love Mill Road. The Mill Road Winter Fair is supported by a Cambridge City Council Community Grant and the Mill Road Traders Association.', style: bodyStyle),
            ],
          ), // Add event details here
        ),
      ),
    );
  }
}
