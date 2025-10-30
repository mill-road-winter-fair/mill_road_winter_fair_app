import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:url_launcher/url_launcher.dart';

class ImportantInfoPage extends StatelessWidget {
  const ImportantInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('ImportantInfoPage build() called');
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Important information'),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child:
                    ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.asset('assets/importantInfoPage/hiVis_cropped.jpg', fit: BoxFit.fitWidth)),
              ),
              const SizedBox(height: 20),
              bulletPoint('Stewards wearing hi-vis jackets are available to assist you.'),
              bulletPoint('To help ensure your safety, please comply promptly with any instructions from stewards.'),
              bulletPoint('If you see anything unsafe or suspicious, please report it to a steward immediately.'),
              bulletPoint('In an emergency, follow instructions from stewards or the emergency services.'),
              bulletPoint('Please respect residents and do not trespass in private gardens.'),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0), child: Image.asset('assets/importantInfoPage/cautionVehicles_cropped.jpg', fit: BoxFit.fitWidth)),
              ),
              const SizedBox(height: 20),
              const Text('Caution – vehicles!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 15),
              bulletPoint(
                  'Whilst Mill Road (between East Road and Coleridge Road), Mortimer Road, Headly Street and the tops of Tenison Road, St Barnabas Road, Devonshire Road, Gwydir Street, Cavendish Road and Catharine Street where they join Mill Road will be closed to traffic (including cyclists and scooters) between 9am and 5.30pm on the day, there will be some vehicle movement.'),
              bulletPoint('Pedestrians should exercise particular care before the road is fully closed.', isBold: true),
              bulletPoint('Re-opening will occur gradually, so drivers and pedestrians should take extreme care.', isBold: true),
              bulletPoint('Pedestrians will be required to make way for emergency and other vehicles within the closure area, from time to time.'),
              const SizedBox(height: 15),
              const Text('First aid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text('If you require first aid, ask the nearest steward or go to Mill Road Baptist Church.'),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0), child: Image.asset('assets/importantInfoPage/carousel01_cropped.jpg', fit: BoxFit.fitWidth)),
              ),
              const SizedBox(height: 20),
              const Text('Coming with children?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              bulletPoint('Please arrange your own family meeting point in case you become separated.'),
              bulletPoint('Report missing children to any steward.'),
              const SizedBox(height: 15),
              const Text('Road closure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                        text:
                            'If your property/business is in the area affected by the road closure, please read the Road Closure Notice distributed separately or available at '),
                    TextSpan(
                        text: 'www.millroadwinterfair.org/rcn',
                        style: const TextStyle(decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            HapticFeedback.lightImpact();
                            launchUrl(Uri.parse('https://www.millroadwinterfair.org/rcn'));
                          }),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text('Updates and contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              bulletPoint('Please follow Mill Road Winter Fair on social media for the latest news and updates or check this app for the latest listings.'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0), // tighten spacing
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(height: 1.2)),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Email addresses for the Fair can be found '),
                            TextSpan(
                                text: 'here',
                                style: const TextStyle(decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    HapticFeedback.lightImpact();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return contactUsDialog(context);
                                      },
                                    );
                                  }),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0), // tighten spacing
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(height: 1.2)),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'On the day, you can also phone '),
                            TextSpan(
                                text: '07303 142689',
                                style: const TextStyle(decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    HapticFeedback.lightImpact();
                                    final Uri phoneUri = Uri(scheme: 'tel', path: '07303 142689');
                                    if (await canLaunchUrl(phoneUri)) {
                                      await launchUrl(phoneUri);
                                    } else {
                                      throw Exception('Could not dial 07303 142689');
                                    }
                                  }),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text('Disclaimer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text(
                  'The Fair (MRWF) is run by a voluntary Committee and key organisers, who plan stalls and activities at set locations within the road closure, Donkey Common, Petersfield Green, Ditchburn Gardens and Gywdir Street Car Park. Official MRWF stalls are given certificates to display. MRWF takes every reasonable effort to ensure the safety of its actions. MRWF accepts no liability for the activities of other traders and organisers. Please refer to our social media pages for the latest updates and news.'),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget bulletPoint(String theText, {isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0), // tighten spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(height: 1.2)),
          Expanded(
            child: Text(
              theText,
              style: TextStyle(height: 1.2, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
