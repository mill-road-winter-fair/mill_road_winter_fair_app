import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ImportantInfoPage extends StatelessWidget {
  const ImportantInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Important Info')),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.asset('assets/importantInfoPage/hiVis.jpg', fit: BoxFit.fitWidth)),
              ),
              const SizedBox(height: 20),
              const Text('Stewards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text(
                  'On the day of the Fair, stewards wearing hi-vis jackets with Mill Road Winter Fair on the back will be available to assist you. To help ensure your safety, please comply promptly with any instructions from stewards. If you see anything suspicious or unsafe, please report it to a steward immediately. In an emergency, follow instructions from stewards or the emergency services.'),
              const SizedBox(height: 20),
              const Text('Mill Road is a residential street. Please respect residents and do not trespass in private gardens.'),
              const SizedBox(height: 40),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0), child: Image.asset('assets/importantInfoPage/cautionVehicles.jpg', fit: BoxFit.fitWidth)),
              ),
              const SizedBox(height: 20),
              const Text('Caution – Vehicles!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text:
                            'While Mill Road (between East Road and Coleridge Road), Mortimer Road, Headly Street and the tops of Gwydir Street, St Barnabas Road, Tenison Road, Cavendish Road, Catharine Street and Devonshire Road '),
                    TextSpan(
                        text: 'will be closed to most traffic (including all cyclists) between 9am and 5.30pm ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text:
                            'on the day, there will be some vehicle movement. Pedestrians should exercise particular care before the road is fully closed. Re-opening will occur gradually, so drivers and pedestrians should take extreme care.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                  'Pedestrians will be required to make way for emergency and other vehicles within the closure area, from time to time. There is no access to the road closure without permission. Permitted vehicles must drive at walking pace, exercise extreme care for pedestrians, and follow any steward instructions.'),
              const SizedBox(height: 40),
              const Text('First Aid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text('If you require first aid, please ask the nearest steward or go to Mill Road Baptist Church.'),
              const SizedBox(height: 40),
              const Text('Missing Children', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text(
                  'Please arrange your own family meeting point in case you become separated. Suggested meeting points are shown on the map. Report missing children to any steward.'),
              const SizedBox(height: 40),
              const Text('Toilets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u2022 Zion Baptist Church', textAlign: TextAlign.left),
                  Text('\u2022 Ditchburn Place (for a small donation)'),
                  Text('\u2022 The Bath House'),
                  Text('\u2022 King’s Church'),
                  Text('\u2022 St Barnabas Church'),
                  Text('\u2022 Mill Road Community Centre'),
                  Text('\u2022 Mill Road Baptist Church (including accessible toilets)'),
                  Text('\u2022 St Philip’s Church'),
                  Text('\u2022 Romsey Mill'),
                  Text('\u2022 Pubs on/near Mill Road.'),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                  'Baby-changing facilities are available at Zion Baptist Church, King’s Church, St Barnabas Church, Mill Road Community Centre, Mill Road Baptist Church, St Philip’s Church and Romsey Mill.'),
              const SizedBox(height: 40),
              const Text('Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text('Please follow Mill Road Winter Fair on social media for the latest news and updates.'),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'If you have any questions about the road closure in advance, email '),
                    TextSpan(
                        text: 'info@millroadwinterfair.org',
                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final Uri mailUri = Uri(scheme: 'mailto', path: 'info@millroadwinterfair.org');
                            if (await canLaunchUrl(mailUri)) {
                              await launchUrl(mailUri);
                            } else {
                              throw Exception('Could not launch email client');
                            }
                          }),
                    const TextSpan(text: ' and on the day phone '),
                    TextSpan(
                        text: '07942 289773',
                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final Uri phoneUri = Uri(scheme: 'tel', path: '07942 289773');
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            } else {
                              throw Exception('Could not launch 07942 28977');
                            }
                          }),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      launchUrl(Uri.parse('https://www.facebook.com/MillRoadWinterFair/'));
                    },
                    icon: FaIcon(FontAwesomeIcons.squareFacebook, size: 60, color: Theme.of(context).colorScheme.tertiary),
                  ),
                  IconButton(
                    onPressed: () {
                      launchUrl(Uri.parse('https://x.com/millroadfair'));
                    },
                    icon: FaIcon(FontAwesomeIcons.squareXTwitter, size: 60, color: Theme.of(context).colorScheme.tertiary),
                  ),
                  IconButton(
                    onPressed: () {
                      launchUrl(Uri.parse('https://www.instagram.com/millroadwinterfair/'));
                    },
                    icon: FaIcon(FontAwesomeIcons.squareInstagram, size: 60, color: Theme.of(context).colorScheme.tertiary),
                  ),
                  IconButton(
                    onPressed: () {
                      launchUrl(Uri.parse('https://www.flickr.com/people/millroadwinterfair/'));
                    },
                    icon: FaIcon(FontAwesomeIcons.flickr, size: 60, color: Theme.of(context).colorScheme.tertiary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
