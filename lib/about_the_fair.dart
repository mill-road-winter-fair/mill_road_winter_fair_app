import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
//import 'package:mill_road_winter_fair_app/main.dart'; // needed if we restore link to Contact Us

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
          children: imageOnLeft? [
            SizedBox(
              height: textHeight,
              width: constraints.maxWidth * (1 - textWidthProportion),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            SizedBox(
              width: constraints.maxWidth * textWidthProportion,
              child: Text.rich(
                textSpan,
              )
            ),
          ] : [
            SizedBox(
              width: constraints.maxWidth * textWidthProportion,
              child: Text.rich(
                textSpan,
              )
            ),
            SizedBox(
              height: textHeight,
              width: constraints.maxWidth * (1 - textWidthProportion),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ],
        );
      },
    );
  }
}

TableRow eventRow(context, eventTime, eventTitle, [List<TextSpan>? eventSubtitle]) {

// Make a row in the events table. Needed as can't style the entire table or pad an entire row in one go

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
          padding: const EdgeInsets.all(4),
          child: Text(eventTime, style: eventsTimeStyle, textAlign: TextAlign.right),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.top,
        child: Container(
          padding: const EdgeInsets.all(3),
          child: Text.rich(TextSpan(children: allTitleSpans))
        ),
      ),
    ],
  );
}

void showDirectionsTo(BuildContext context, String id, LatLng theDest) {

  mapPageKey.currentState?.getDirections(id, theDest, true);
  // Switch to map tab on the home page
  homePageKey.currentState?.setCurrentIndex(0);

}

class AboutTheFairPage extends StatelessWidget {
  const AboutTheFairPage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('AboutTheFairPage build() called');
    var bodyStyle = TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary);
    var eventsSubtitleStyle = TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onPrimary, height: 1.2);
    var eventsSubtitleLinkStyle = eventsSubtitleStyle.copyWith(decoration: TextDecoration.underline, decorationColor: Theme.of(context).colorScheme.onPrimary);
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('About Mill Road Winter Fair'),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              const TextImageRow(
                textSpan: TextSpan(text: 'Mill Road Winter Fair is a celebration of community along one of the most diverse and vibrant roads in Cambridge. Usually held on the first Saturday of December, the Fair brings together local businesses and organisations, shops and stallholders, musicians, artists and dancers in one day of festival joy.',),
                imagePath: "assets/aboutPage/MRWF25_people_hat.png",
                textWidthProportion: 0.75,
              ),
              const SizedBox(height: 12),
              Text('The 2025 Fair will be on Saturday 6th December, 10.30am to 4.30pm.', style: bodyStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const TextImageRow(
                textSpan: TextSpan(text: 'This year, we celebrate 20 years since the first Fair in 2005! It’s been a remarkable journey, but we still hold true to the Fair’s original aim of celebrating all that is great about the Mill Road area. We have a huge range of activities to discover throughout the day; it’s sure to be the best Fair yet! Be sure to come early so that you don’t miss out!',),
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
                    width: 227,
                    // Flutter tables don't support spanning, so need two of them to do a header row
                    child: Column(children: [Table(
                      columnWidths: const <int, TableColumnWidth>{
                        0: FixedColumnWidth(227),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: <TableRow>[
                        TableRow(
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                          children: <Widget> [
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.top,
                              child: Container(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text('Key events', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Table(
                      columnWidths: const <int, TableColumnWidth>{
                        0: FixedColumnWidth(50),
                        1: FixedColumnWidth(177),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: <TableRow>[
                        eventRow(context, '9.00', 'Road closure starts'),
                        eventRow(context, '10.30', 'Winter Fair opens'),
                        eventRow(context, '10.30', 'Fire engine pull\n', 
                          [
                            TextSpan(
                              text: 'East Road',
                              style: eventsSubtitleLinkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () 
                                {
                                  HapticFeedback.lightImpact();
                                  showDirectionsTo(context, 'East Road', const LatLng(52.202488, 0.131207));
                                }
                            ),
                            TextSpan(text: ' to ', style: eventsSubtitleStyle),
                            TextSpan(
                              text: 'the bridge',
                              style: eventsSubtitleLinkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  HapticFeedback.lightImpact();
                                  showDirectionsTo(context, 'Mill Road bridge', const LatLng(52.198682, 0.141051));
                                }
                            ),
                          ],
                        ),
                        eventRow(context, '10.30', 'Opening ceremony\n',
                          [
                            TextSpan(
                              text: 'Ditchburn Gardens',
                              style: eventsSubtitleLinkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  HapticFeedback.lightImpact();
                                  showDirectionsTo(context, 'Ditchburn Gardens', const LatLng(52.200389, 0.136465));
                                }),
                          ],
                        ),
                        eventRow(context, '11.45', 'Parade\n',
                          [
                            TextSpan(
                              text: 'Salisbury Club',
                              style: eventsSubtitleLinkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  HapticFeedback.lightImpact();
                                  showDirectionsTo(context, 'Salisbury Club', const LatLng(52.1970778,0.1472252));
                                }
                            ),
                            TextSpan(text: ' to ', style: eventsSubtitleStyle),
                            TextSpan(
                              text: 'Petersfield',
                              style: eventsSubtitleLinkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  HapticFeedback.lightImpact();
                                  showDirectionsTo(context, 'Petersfield', const LatLng(52.202858, 0.132253));
                                }
                            ),
                          ],
                        ),
                        eventRow(context, '3.40', 'Final parade\n',
                          [
                            TextSpan(
                              text: 'Gwydir Street',
                              style: eventsSubtitleLinkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  HapticFeedback.lightImpact();
                                  showDirectionsTo(context, 'Gwydir Street', const LatLng(52.199627, 0.138407));
                                }
                            ),
                            TextSpan(text: ' to ', style: eventsSubtitleStyle),
                            TextSpan(
                              text: 'Petersfield',
                              style: eventsSubtitleLinkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  HapticFeedback.lightImpact();
                                  showDirectionsTo(context, 'Petersfield', const LatLng(52.202858, 0.132253));
                                }
                            ),
                          ],
                        ),
                        eventRow(context, '4.15', 'All trading ends'),
                        eventRow(context, '4.30', 'Winter Fair ends'),
                        eventRow(context, '5.30', 'Roads fully open'),
                      ],
                    ),],
                    )
                  ),
                  SizedBox(
                    width: 70,
                    child: Image.asset("assets/aboutPage/MRWF25_trafficlights.png", fit: BoxFit.fill, width: 70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const TextImageRow(
                textSpan: TextSpan(text: 'We are grateful for the generous support of Bush & Co Sales and Lettings (lead sponsor), Al-Amin, Anglia Ruskin University, Hughes Hall, Love Mill Road, Regalstar Catering and Taank Optometrists. The Fair benefits from a Cambridge City Council Community Grant and the ongoing help of the Mill Road Traders Association.',),
                imagePath: "assets/aboutPage/MRWF25_people_juggle.png",
                textWidthProportion: 0.75,
                imageOnLeft: true,
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.fill,
                child: Image.asset("assets/aboutPage/MRWF25_sponsor_logos.png"),
              ),
              const SizedBox(height: 12),
            ],
          ), // Add event details here
        ),
      ),
    );
  }
}
