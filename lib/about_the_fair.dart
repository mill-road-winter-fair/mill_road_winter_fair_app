import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:url_launcher/url_launcher.dart';

class TextImageRow extends StatelessWidget {
  final TextSpan textSpan;
  final String imagePath;
  final double textWidthProportion;
  final bool imageOnLeft;

  const TextImageRow({super.key, required this.textSpan, required this.imagePath, required this.textWidthProportion, this.imageOnLeft = false});

  double _measureTextHeight(TextSpan textSpan, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      maxLines: null,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return textPainter.size.height;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textHeight = _measureTextHeight(textSpan, constraints.maxWidth * textWidthProportion);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: imageOnLeft
              ? [
                  SizedBox(
                    height: textHeight,
                    width: constraints.maxWidth * (1 - textWidthProportion) - 2,
                    child: Image.asset(imagePath, fit: BoxFit.contain, alignment: Alignment.centerLeft),
                  ),
                  const Expanded(child: SizedBox()),
                  SizedBox(
                      width: constraints.maxWidth * textWidthProportion,
                      child: Text.rich(
                        textSpan,
                      )),
                ]
              : [
                  SizedBox(
                      width: constraints.maxWidth * textWidthProportion,
                      child: Text.rich(
                        textSpan,
                      )),
                  const Expanded(child: SizedBox()),
                  SizedBox(
                    height: textHeight,
                    width: constraints.maxWidth * (1 - textWidthProportion) - 2,
                    child: Image.asset(imagePath, fit: BoxFit.contain, alignment: Alignment.centerRight),
                  ),
                ],
        );
      },
    );
  }
}

// Make a row in the events table. Needed as can't style the entire table or pad an entire row in one go
TableRow eventRow(BuildContext context, String eventTime, String eventTitle, [List<TextSpan>? eventSubtitle]) {
  var eventsTimeStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary, height: 1.2);
  var eventsTitleStyle = TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimary, height: 1.2);

  final List<TextSpan> allTitleSpans;

  if (eventSubtitle != null && eventSubtitle.isNotEmpty) {
    allTitleSpans = [TextSpan(text: eventTitle, style: eventsTitleStyle), ...eventSubtitle];
  } else {
    allTitleSpans = [TextSpan(text: eventTitle, style: eventsTitleStyle)];
  }

  return TableRow(
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
    children: <Widget>[
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.top,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 2, 4), 
          child: FittedBox(
            fit: BoxFit.scaleDown, 
            child: Text(eventTime, style: eventsTimeStyle, textAlign: TextAlign.right),
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.top,
        child: Container(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 4), 
          child: Text.rich(TextSpan(children: allTitleSpans))
        ),
      ),
    ],
  );
}

void showDirectionsTo(BuildContext context, String id, LatLng theDest) async {
  debugPrint('showDirectionsTo build() called for id: $id');
  // Set previousIndex to map page
  previousIndex = 0;

  // Switch to map tab on the home page
  homePageKey.currentState?.setCurrentIndex(0);

  // We only want to attempt this kind of navigation if we already have the listings
  // Otherwise, the map page will handle it when the listings eventually load
  if (listings.isNotEmpty) {
    // Request the map page to show directions
    await mapPageKey.currentState?.getDirections(id, theDest, true);
  }
}

class AboutTheFairPage extends StatefulWidget {
  const AboutTheFairPage({super.key});

  @override
  State<AboutTheFairPage> createState() => _AboutTheFairPageState();
}

class _AboutTheFairPageState extends State<AboutTheFairPage> {
  late ScrollController _aboutPageScrollController;

  // Define sponsors and placeholder URLs - user will fill these in
  final Map<String, String> _sponsorUrls = {
    'Bush & Co Sales and Lettings': 'https://bushandco.co.uk/',
    'Al-Amin': 'https://www.alamin.co.uk/',
    'Anglia Ruskin University': 'https://www.aru.ac.uk/',
    'Hughes Hall': 'https://www.hughes.cam.ac.uk/',
    'Love Mill Road': 'https://www.lovemillroad.org.uk/',
    'Regal Star Catering': 'https://www.lamaisondusteak.co.uk/',
    'Taank Optometrists': 'https://taank.co.uk/',
  };

  final Map<String, TapGestureRecognizer> _recognizers = {};

  @override
  void initState() {
    super.initState();
    _aboutPageScrollController = ScrollController();
    // Create recognizers for each sponsor so we can dispose them later
    for (var name in _sponsorUrls.keys) {
      _recognizers[name] = TapGestureRecognizer()..onTap = () => _onSponsorTap(name);
    }
  }

  @override
  void dispose() {
    _aboutPageScrollController.dispose();
    for (var r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  void _onSponsorTap(String name) {
    final url = _sponsorUrls[name] ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sponsor URL not set')));
      return;
    }
    HapticFeedback.lightImpact();
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AboutTheFairPage build() called');
    var bodyStyle = TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.tertiary);
    var eventsSubtitleStyle = TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onPrimary, height: 1.2);
    var eventsSubtitleLinkStyle = eventsSubtitleStyle.copyWith(decoration: TextDecoration.underline, decorationColor: Theme.of(context).colorScheme.onPrimary);

    // Build a list of TextSpans for sponsors so we can special-case the Bush entry
    final List<TextSpan> sponsorSpans = [];
    final sponsorKeys = _sponsorUrls.keys.toList();
    var sponsorLinkStyle = const TextStyle(decoration: TextDecoration.underline);
    for (var i = 0; i < sponsorKeys.length; i++) {
      final name = sponsorKeys[i];
      final isLast = i == sponsorKeys.length - 1;
      final isSecondLast = i == sponsorKeys.length - 2;

      if (name == 'Bush & Co Sales and Lettings') {
        sponsorSpans.add(TextSpan(text: name, style: sponsorLinkStyle, recognizer: _recognizers[name]));
        // Add non-clickable lead sponsor annotation
        sponsorSpans.add(const TextSpan(text: ' (lead sponsor)'));
      } else {
        sponsorSpans.add(TextSpan(text: name, style: sponsorLinkStyle, recognizer: _recognizers[name]));
      }

      if (!isLast) {
        sponsorSpans.add(TextSpan(text: isSecondLast ? ' and ' : ', '));
      } else {
        sponsorSpans.add(const TextSpan(text: '. '));
      }
    }

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: Scaffold(
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('About Mill Road Winter Fair'),
          ),
        ),
        body: Container(width: min(MediaQuery.of(context).size.width - 8, 500),
          padding: EdgeInsets.all(4.0 + ((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt()),
          child: Scrollbar(
            controller: _aboutPageScrollController,
            thumbVisibility: Platform.isIOS ? false : true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SingleChildScrollView(
                controller: _aboutPageScrollController,
                primary: false,
                child: Column(
                  children: [
                    const TextImageRow(
                      textSpan: TextSpan(
                        text:
                            'Mill Road Winter Fair is a celebration of community along one of the most diverse and vibrant roads in Cambridge. Usually held on the first Saturday of December, the Fair brings together local businesses and organisations, shops and stallholders, musicians, artists and dancers in one day of festival joy.',
                      ),
                      imagePath: "assets/aboutPage/MRWF25_people_hat.png",
                      textWidthProportion: 0.75,
                    ),
                    const SizedBox(height: 12),
                    Text('The 2025 Fair will be on Saturday 6th December, 10:30 to 16:30.', style: bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const TextImageRow(
                      textSpan: TextSpan(
                        text:
                            'This year, we celebrate 20 years since the first Fair in 2005! It’s been a remarkable journey, but we still hold true to the Fair’s original aim of celebrating all that is great about the Mill Road area. We have a huge range of activities to discover throughout the day; it’s sure to be the best Fair yet! Be sure to come early so that you don’t miss out!',
                      ),
                      imagePath: "assets/aboutPage/MRWF25_people_cake.png",
                      textWidthProportion: 0.67,
                      imageOnLeft: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 221,
                          // Flutter tables don't support spanning, so need two of them to do a header row
                          child: Column(
                            children: [
                              Table(
                                columnWidths: const <int, TableColumnWidth>{
                                  0: FixedColumnWidth(150),
                                  1: FixedColumnWidth(71),
                                },
                                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                                children: <TableRow>[
                                  TableRow(
                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                                    children: <Widget>[
                                      TableCell(
                                        verticalAlignment: TableCellVerticalAlignment.middle,
                                        child: Container(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Text('Key events',
                                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary, height: 1.0)),
                                        ),
                                      ),
                                      TableCell(
                                        verticalAlignment: TableCellVerticalAlignment.top,
                                        child: SizedBox(
                                            width: 71,
                                            child: Image.asset('assets/aboutPage/MRWF25_bird.png', fit: BoxFit.contain, alignment: Alignment.centerLeft),
                                          ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Table(
                                columnWidths: const <int, TableColumnWidth>{
                                  0: FixedColumnWidth(44),
                                  1: FixedColumnWidth(177),
                                },
                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                children: <TableRow>[
                                  eventRow(context, '09:00', 'Road closure starts'),
                                  eventRow(context, '10:30', 'Winter Fair opens'),
                                  eventRow(
                                    context,
                                    '10:30',
                                    'Fire engine pull\n',
                                    [
                                      TextSpan(
                                          text: 'East Road',
                                          style: eventsSubtitleLinkStyle,
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              HapticFeedback.lightImpact();
                                              showDirectionsTo(context, '$aSimpleMarkerId Event', const LatLng(52.202488, 0.131207));
                                            }),
                                      TextSpan(text: ' to ', style: eventsSubtitleStyle),
                                      TextSpan(
                                          text: 'the bridge',
                                          style: eventsSubtitleLinkStyle,
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              HapticFeedback.lightImpact();
                                              showDirectionsTo(context, '$aSimpleMarkerId Event', const LatLng(52.198682, 0.141051));
                                            }),
                                    ],
                                  ),
                                  eventRow(
                                    context,
                                    '10:30',
                                    'Opening ceremony\n',
                                    [
                                      TextSpan(
                                          text: 'Ditchburn Gardens',
                                          style: eventsSubtitleLinkStyle,
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              HapticFeedback.lightImpact();
                                              showDirectionsTo(context, '$aSimpleMarkerId Event', const LatLng(52.200389, 0.136465));
                                            }),
                                    ],
                                  ),
                                  eventRow(
                                    context,
                                    '11:45',
                                    'Parade\n',
                                    [
                                      TextSpan(
                                          text: 'Salisbury Club',
                                          style: eventsSubtitleLinkStyle,
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              HapticFeedback.lightImpact();
                                              showDirectionsTo(context, '$aSimpleMarkerId Event', const LatLng(52.1970778, 0.1472252));
                                            }),
                                      TextSpan(text: ' to ', style: eventsSubtitleStyle),
                                      TextSpan(
                                          text: 'Petersfield',
                                          style: eventsSubtitleLinkStyle,
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              HapticFeedback.lightImpact();
                                              showDirectionsTo(context, '$aSimpleMarkerId Event', const LatLng(52.202858, 0.132253));
                                            }),
                                    ],
                                  ),
                                  eventRow(
                                    context,
                                    '15:40',
                                    'Final parade\n',
                                    [
                                      TextSpan(
                                          text: 'Gwydir Street',
                                          style: eventsSubtitleLinkStyle,
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              HapticFeedback.lightImpact();
                                              showDirectionsTo(context, '$aSimpleMarkerId Event', const LatLng(52.199627, 0.138407));
                                            }),
                                      TextSpan(text: ' to ', style: eventsSubtitleStyle),
                                      TextSpan(
                                          text: 'Petersfield',
                                          style: eventsSubtitleLinkStyle,
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              HapticFeedback.lightImpact();
                                              showDirectionsTo(context, '$aSimpleMarkerId Event', const LatLng(52.202858, 0.132253));
                                            }),
                                    ],
                                  ),
                                  eventRow(context, '16:15', 'All trading ends'),
                                  eventRow(context, '16:30', 'Winter Fair ends'),
                                  eventRow(context, '17:30', 'Roads fully open'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        SizedBox(
                          width: 70,
                          child: Image.asset("assets/aboutPage/MRWF25_trafficlights.png", fit: BoxFit.fill, width: 70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextImageRow(
                      textSpan: TextSpan(
                        children: [
                          const TextSpan(text: 'We are grateful for the generous support of '),
                          TextSpan(text: '', style: sponsorLinkStyle),
                          const TextSpan(text: ''),
                          // Sponsor spans
                          const TextSpan(text: ''),
                          // Build sponsor spans with separators
                          ...sponsorSpans,
                          const TextSpan(
                              text: 'The Fair benefits from a Cambridge City Council Community Grant and the ongoing help of the Mill Road Traders Association.'),
                        ],
                      ),
                      imagePath: "assets/aboutPage/MRWF25_people_juggle.png",
                      textWidthProportion: 0.75,
                      imageOnLeft: true,
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.fill,
                      child: Image.asset("assets/aboutPage/MRWF25_sponsor_logos.png"),
                    ),
                    const SizedBox(height: 16),
                  ],
                ), // Add event details here
              ),
            ),
          ),
        ),
      ),
    );
  }
}
