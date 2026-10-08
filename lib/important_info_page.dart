import 'dart:io';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:url_launcher/url_launcher.dart';

class ImportantInfoPage extends StatefulWidget {
  final AnalyticsService analyticsService;

  const ImportantInfoPage({super.key, required this.analyticsService});

  @override
  State<ImportantInfoPage> createState() => _ImportantInfoPageState();
}

class _ImportantInfoPageState extends State<ImportantInfoPage> with RouteAware {
  late final TapGestureRecognizer _phoneLinkRecognizer = TapGestureRecognizer()
    ..onTap = () {
      HapticFeedback.lightImpact();
      widget.analyticsService.logButtonTapped('contact_phone');
      launchUrl(Uri(scheme: 'tel', path: '07486398744'));
    };

  @override
  void initState() {
    debugPrint('_ImportantInfoPageState initState() called');
    super.initState();
  }

  @override
  void dispose() {
    debugPrint('_ImportantInfoPageState dispose() called');
    routeObserver.unsubscribe(this);
    _phoneLinkRecognizer.dispose();
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
    widget.analyticsService.setCurrentScreen('ImportantInfoPage');
  }

  @override
  void didPopNext() {
    widget.analyticsService.setCurrentScreen('ImportantInfoPage');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ImportantInfoPage build() called');
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
            child: Text('Important information'),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            width: min(MediaQuery.of(context).size.width - 8, 500),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child:
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.asset('assets/importantInfoPage/hiVis_cropped.jpg',
                              fit: BoxFit.fitWidth, semanticLabel: 'Mill Road Winter Fair stewards wearing high-visibility jackets')),
                ),
                const SizedBox(height: 20),
                bulletPoint('Stewards wearing hi-vis jackets are available to assist you.'),
                bulletPoint('To help ensure everyone’s safety, please comply promptly with any instructions from stewards.'),
                bulletPoint('If you see anything unsafe or suspicious, please report it to a steward immediately.'),
                bulletPoint('Please respect residents and do not trespass in private gardens.'),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset('assets/importantInfoPage/cautionVehicles_cropped.jpg',
                          fit: BoxFit.fitWidth, semanticLabel: 'A caution sign warning that vehicles may be moving through the Fair')),
                ),
                const SizedBox(height: 20),
                const Text('Caution – vehicles!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 15),
                bulletPoint(
                    'Whilst roads (as shown on the map) will be closed to traffic (including cyclists and scooters) between 9am and 5.30pm, there will be some vehicle movement.'),
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
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset('assets/importantInfoPage/carousel01_cropped.jpg',
                          fit: BoxFit.fitWidth, semanticLabel: 'Children riding a carousel at Mill Road Winter Fair')),
                ),
                const SizedBox(height: 20),
                const Text('Coming with children?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 10),
                bulletPoint('Please arrange your own family meeting point in case you become separated.'),
                bulletPoint('Report missing children to any steward.'),
                const SizedBox(height: 15),
                const Text('Keep the pavement clear – Keep the fair alive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                          text:
                              'If your business is within the road closure, please read the Important Safety Guidelines for Local Businesses you have been sent or available at '),
                      TextSpan(
                          text: 'www.millroadwinterfair.org',
                          style: const TextStyle(decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              HapticFeedback.lightImpact();
                              widget.analyticsService.logButtonTapped('mrwf_business_safety_hyperlink');
                              launchUrl(Uri.parse('https://www.millroadwinterfair.org'));
                            }),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Road closure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                          text:
                              'To find out more about the road closure, please read the Road Closure Notice distributed separately or available at '),
                      TextSpan(
                          text: 'www.millroadwinterfair.org',
                          style: const TextStyle(decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              HapticFeedback.lightImpact();
                              widget.analyticsService.logButtonTapped('mrwf_website_hyperlink');
                              launchUrl(Uri.parse('https://www.millroadwinterfair.org'));
                            }),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Updates and contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 10),
                bulletPoint('Follow Mill Road Winter Fair on social media for the latest news and updates and check this app for the latest listings.'),
                bulletPoint(
                  'On-the-day phone number: ',
                  link: TextSpan(
                    text: '07486 398744',
                    style: const TextStyle(decoration: TextDecoration.underline),
                    recognizer: _phoneLinkRecognizer,
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Our responsibilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 10),
                const Text(
                    'The Fair (MRWF) is organised by unpaid volunteers, constituted as Mill Road Winter Fair CIC, who plan stalls, activities and entertainment at designated locations throughout the road closure and Donkey Common, Petersfield, Ditchburn Gardens and Gwydir Street Car Park. Official MRWF stalls will be issued with certificates to display. MRWF makes every reasonable effort to ensure the safety of its actions. MRWF accepts no liability for the activities of other traders and organisers.'),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget bulletPoint(String theText, {isBold = false, TextSpan? link}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0), // tighten spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(height: 1.3)),
          Expanded(
            child: Text.rich(
              TextSpan(text: theText, children: [if (link != null) link]),
              style: TextStyle(height: 1.3, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
