import 'package:flutter/material.dart';

class AboutTheFairPage extends StatelessWidget {
  const AboutTheFairPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Mill Road Winter Fair")),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                  "Mill Road Winter Fair is a celebration of community along one of the most diverse and vibrant roads in Cambridge. Usually held on the first Saturday of December, the Fair brings together local businesses and organisations, shops and stallholders, musicians, artists and dancers in one day of festival joy."),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: CarouselView(
                  itemExtent: MediaQuery.of(context).size.width - 80,
                  shrinkExtent: MediaQuery.of(context).size.width - 80,
                  elevation: 3.0,
                  itemSnapping: true,
                  children: [
                    Image.asset('assets/carousel01.jpg', fit: BoxFit.fitWidth),
                    Image.asset('assets/carousel02.jpg', fit: BoxFit.fitWidth),
                    Image.asset('assets/carousel03.jpg', fit: BoxFit.fitWidth),
                    Image.asset('assets/carousel04.jpg', fit: BoxFit.fitWidth),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('The 2025 Fair will be on Saturday 6th December, 10.30am to 4.30pm.', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Be sure to come early so that you don’t miss out! We have so much to see! The fire engine pull, opening ceremony, dance show and parade are all in the morning, as well as lots of amazing stalls, performance and events.'),
              const SizedBox(height: 8),
              const Text('There are lots of opportunities to volunteer for the Fair – from communications, finding performers, setting stuff up, stewarding and just plain old organising – so do get in touch if you’d like to get involved. If you have a question about or idea for the 2025 Fair, please email us.'),
              const SizedBox(height: 8),
              const Text('We also have a number of Fringe events throughout the year, which we’d love you to get involved with.'),
            ],
          ), // Add event details here
        ),
      ),
    );
  }
}
