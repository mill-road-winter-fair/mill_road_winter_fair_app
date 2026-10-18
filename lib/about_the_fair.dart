import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:url_launcher/url_launcher.dart';


class TextImageRow extends StatelessWidget {
  final TextSpan textSpan;
  final String imagePath;
  final bool imageOnLeft;
  final TextStyle textStyle;

  const TextImageRow({
    super.key,
    required this.textSpan,
    required this.imagePath,
    this.imageOnLeft = false,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final plainText = textSpan.toPlainText();
        final length = plainText.length;
        final textProportion = (0.65 + (length - 150) / 1500).clamp(0.55, 0.75).toDouble();
        final spacing = imageOnLeft ? 16.0 : 2.0;
        final textWidth = availableWidth * textProportion - spacing / 2;
        final imageWidth = availableWidth - textWidth - spacing;
        final text = SizedBox(width: textWidth, child: Text.rich(textSpan, style: textStyle));
        final image = SizedBox(
          width: imageWidth,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            alignment: imageOnLeft
                ? Alignment.topLeft
                : Alignment.topRight,
          ),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: spacing,
          children: imageOnLeft ? [image, text] : [text, image],
        );
      },
    );
  }
}


// Make a row in the events table. Needed as can't style the entire table or pad an entire row in one go
TableRow eventRow(ColorScheme colorScheme, String eventTime, String eventTitle, [List<TextSpan>? eventSubtitle]) {
  var eventsTitleStyle = TextStyle(fontSize: 17, color: colorScheme.onPrimary, height: 1.2);
  var eventsTimeStyle = eventsTitleStyle.copyWith(fontWeight: FontWeight.bold);

  final List<TextSpan> allTitleSpans;

  if (eventSubtitle != null && eventSubtitle.isNotEmpty) {
    allTitleSpans = [TextSpan(text: eventTitle, style: eventsTitleStyle), ...eventSubtitle];
  } else {
    allTitleSpans = [TextSpan(text: eventTitle, style: eventsTitleStyle)];
  }

  return TableRow(
    decoration: BoxDecoration(color: colorScheme.primary),
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
        child: Container(padding: const EdgeInsets.fromLTRB(2, 4, 2, 4), child: Text.rich(TextSpan(children: allTitleSpans))),
      ),
    ],
  );
}


class AboutTheFairPage extends StatefulWidget {
  final AnalyticsService analyticsService;
  const AboutTheFairPage({super.key, required this.analyticsService});

  @override
  State<AboutTheFairPage> createState() => _AboutTheFairPageState();
}

class _AboutTheFairPageState extends State<AboutTheFairPage> with RouteAware {
  late ScrollController _aboutPageScrollController;

  // Define sponsors and placeholder URLs - user will fill these in
  static const Map<String, String> _sponsorUrls = {
    'Bush & Co Sales and Lettings': 'https://bushandco.co.uk/',
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
    routeObserver.unsubscribe(this);
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
    widget.analyticsService.setCurrentScreen('AboutPage');
  }

  @override
  void didPopNext() {
    widget.analyticsService.setCurrentScreen('AboutPage');
  }

  void _onSponsorTap(String name) {
    final url = _sponsorUrls[name] ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sponsor URL not set')));
      return;
    }
    HapticFeedback.lightImpact();
    widget.analyticsService.logButtonTapped('sponsor_${name.replaceAll(' ', '_')}_hyperlink');
    launchUrl(Uri.parse(url));
  }

  TextSpan directionableLocation(String location, TextStyle style, LatLng locationLatLng) {
    return TextSpan(
      text: location,
      style: style,
      recognizer: TapGestureRecognizer()..onTap = () {
        HapticFeedback.lightImpact();
        widget.analyticsService.logButtonTapped('directionableLocation_hyperlink');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapPage(
              listings: listings,
              onTabSelected: (_) => {},
              destinationId: '$aSimpleMarkerId Visit/Experience',
              destinationLatLng: locationLatLng,
              analyticsService: widget.analyticsService,
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AboutTheFairPage build() called');
    final colorScheme = Theme.of(context).colorScheme;
    final bodyStyle = TextStyle(fontSize: 17);
    final eventsSubtitleStyle = TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: colorScheme.onPrimary);
    final eventsSubtitleLinkStyle = eventsSubtitleStyle.copyWith(decoration: TextDecoration.underline, decorationColor: colorScheme.onPrimary);

    // Build a list of TextSpans for sponsors so we can special-case the Bush entry
    final List<TextSpan> sponsorSpans = [];
    final sponsorKeys = _sponsorUrls.keys.toList();
    final sponsorLinkStyle = const TextStyle(decoration: TextDecoration.underline);
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
          leading: Navigator.canPop(context) ? BackButton(onPressed: () {
            HapticFeedback.lightImpact();
            widget.analyticsService.logButtonTapped('back');
            Navigator.maybePop(context);
          }) : null,
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('About Mill Road Winter Fair'),
          ),
        ),
        body: Scrollbar(
            controller: _aboutPageScrollController,
            thumbVisibility: Platform.isIOS ? false : true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(6.0 + ((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt()),
              child: SingleChildScrollView(
                controller: _aboutPageScrollController,
                primary: false,
                child: Column(
                  spacing: 12,
                  children: [
                    TextImageRow(
                      textSpan: TextSpan(
                        text: 'Mill Road Winter Fair is a celebration of community along one of the most diverse and vibrant roads in Cambridge.',
                      ),
                      imagePath: "assets/chooserPage/nearby.png",
                      textStyle: bodyStyle,
                    ),
                    TextImageRow(
                      textSpan: TextSpan(
                        text: 'Usually held on the first Saturday of December, the Fair brings together local businesses and organisations, '
                        'shops and stallholders, musicians, artists and dancers in one day of festival joy.',
                      ),
                      imagePath: "assets/chooserPage/music.png",
                      imageOnLeft: true,
                      textStyle: bodyStyle,
                    ),
                    SizedBox.shrink(),
                    Container(color: colorScheme.tertiary, padding: EdgeInsets.all(4),
                      child: Text('The 2026 Fair will be held on Saturday 5th December, 10:30 to 16:30.', textAlign: TextAlign.center,
                      style: bodyStyle.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimary)),
                    ),
                    SizedBox.shrink(),
                    TextImageRow(
                      textSpan: TextSpan(
                        text: 'This year, we celebrate 21 years since the first Fair in 2005! It’s been a remarkable journey, '
                            'but we still hold true to the Fair’s original aim of celebrating all that is great about the Mill Road area.'
                      ),
                      imagePath: "assets/chooserPage/childrens.png",
                      textStyle: bodyStyle,
                    ),
                    TextImageRow(
                      textSpan: TextSpan(
                        text: 'We have a huge range of activities to discover throughout the day; it’s sure to be the best Fair yet! '
                            'Be sure to come early so that you don’t miss out!',
                      ),
                      imagePath: "assets/chooserPage/foodDrink.png",
                      imageOnLeft: true,
                      textStyle: bodyStyle,
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 88, right: 20, bottom: 24),
                              child: Table(
                                columnWidths: const <int, TableColumnWidth>{0: FractionColumnWidth(0.25), 1: FractionColumnWidth(0.75)},
                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                children: [
                                  eventRow(colorScheme, '09:00', 'Road closure starts'),
                                  eventRow(colorScheme, '10:30', 'Winter Fair opens'),
                                  eventRow(colorScheme, '10:30', 'Fire engine pull\n',
                                    [
                                      directionableLocation('East Road', eventsSubtitleLinkStyle, LatLng(52.202488, 0.131207)),
                                      TextSpan(text: ' to ', style: eventsSubtitleStyle),
                                      directionableLocation('the bridge', eventsSubtitleLinkStyle, const LatLng(52.198682, 0.141051)),
                                    ],
                                  ),
                                  eventRow(colorScheme, '10:30', 'Opening ceremony\n',
                                    [directionableLocation('Ditchburn Gardens', eventsSubtitleLinkStyle, LatLng(52.200389, 0.136465))],
                                  ),
                                  eventRow(colorScheme, '11:45', 'Parade\n',
                                    [
                                      directionableLocation('Salisbury Club', eventsSubtitleLinkStyle, LatLng(52.1970778, 0.1472252)),
                                      TextSpan(text: ' to ', style: eventsSubtitleStyle),
                                      directionableLocation('Petersfield', eventsSubtitleLinkStyle, LatLng(52.202858, 0.132253)),
                                    ],
                                  ),
                                  eventRow(colorScheme, '15:40', 'Final parade\n',
                                    [
                                      directionableLocation('Gwydir Street', eventsSubtitleLinkStyle, const LatLng(52.199627, 0.138407)),
                                      TextSpan(text: ' to ', style: eventsSubtitleStyle),
                                      directionableLocation('Petersfield', eventsSubtitleLinkStyle, LatLng(52.202858, 0.132253)),
                                    ],
                                  ),
                                  eventRow(colorScheme, '16:15', 'All trading ends'),
                                  eventRow(colorScheme, '16:30', 'Winter Fair ends'),
                                  eventRow(colorScheme, '17:30', 'Roads fully open'),
                                  TableRow(decoration: BoxDecoration(color: colorScheme.primary), children: [SizedBox(height: 10), SizedBox(height: 10)]),
                                ],
                              ),
                            ),
                            Positioned(top: 40, left: 0, right: 20,
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.all(8),
                                color: colorScheme.primary,
                                alignment: Alignment.centerLeft,
                                child: Text('Key events', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onPrimary, height: 1.0),
                                ),
                              ),
                            ),
                            Positioned(top: 0, right: 0, child: Image.asset('assets/chooserPage/charityCommunityInfo.png', fit: BoxFit.contain, height: 145)),
                            Positioned(bottom: 0, right: 0, child: Image.asset('assets/chooserPage/visitExperience.png', fit: BoxFit.contain, height: 120)),
                          ],
                        )),
                      ], 
                    ),
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
                        ],
                      ),
                      imagePath: "assets/chooserPage/shopping.png",
                      imageOnLeft: true,
                      textStyle: bodyStyle,
                    ),
                    TextImageRow(
                      textSpan: TextSpan(
                        children: [
                          const TextSpan(text: 'The Fair is entirely run by volunteers and benefits from a Cambridge City Council '
                            'Community Grant and the ongoing help of the Mill Road Traders Association.'),
                        ],
                      ),
                      imagePath: "assets/chooserPage/services.png",
                      textStyle: bodyStyle,
                    ),
                    FittedBox(
                      fit: BoxFit.fill,
                      child: Image.asset("assets/aboutPage/MRWF25_sponsor_logos.png"),
                    ),
                    const SizedBox(height: 4),
                  ],
                ), // Add event details here
              ),
            ),
          ),
      ),
    );
  }
}
