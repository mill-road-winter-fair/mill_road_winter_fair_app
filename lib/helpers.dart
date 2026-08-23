import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';

OverlayEntry? _miniPopupOverlayEntry; // widget that floats over a given widget as a 'tooltip'
Timer? _miniPopupTimer; // times how long the above stays on screen
Route? listingDetailsDialogRoute; // to keep track of dialog so it can be closed if needed. This will move to main if we enter the app from an alert

class FairScaffold extends StatelessWidget {
  const FairScaffold({
    super.key,
    required this.appBarTitle,
    required this.body,
    this.appBarActions = const [],
    required this.currentTab,
    required this.onTabSelected,
    this.allowBack,
  });
  final String appBarTitle;
  final Widget body;
  final List<Widget> appBarActions;
  final int currentTab;
  final ValueChanged<int> onTabSelected;
  final bool? allowBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leadingWidth: 44,
          leading: (allowBack ?? false) ? const BackButton() : Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(appBarTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          centerTitle: false,
          actions: appBarActions.map((a) => SizedBox(width: 36, child: a)).toList(),
          actionsPadding: EdgeInsets.only(right: 4),
        ),
        body: body,
        drawer: fairDrawer(context),
        bottomNavigationBar: (allowBack ?? false) ? null : fairBottomNavigationBar(currentTab, onTabSelected),
      )
    );
  }

}


BottomNavigationBar fairBottomNavigationBar(int index, ValueChanged<int> onTabSelected) {
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    showUnselectedLabels: true,
    elevation: 0,
    currentIndex: index,
    selectedFontSize: 12,
    unselectedFontSize: 12,
    iconSize: 30,
    onTap: (selectedIndex) {
      HapticFeedback.selectionClick();
      onTabSelected.call(selectedIndex);
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
      BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Timetable"),
      BottomNavigationBarItem(icon: Icon(Icons.list), label: "Listings"),
      BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favourites"),
    ],
  );
}


Drawer fairDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      spacing: 0,
      children: <Widget>[
        Expanded(
          flex: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 380),
            child: DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 4, child: Container()),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Image.asset('assets/MRWF25_leaflet_banner.png', fit: BoxFit.contain),
                  ),
                  Expanded(flex: 2, child: Container()),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(' $fairDateTimes',
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(flex: 2, child: Container())
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About the Fair', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Important information', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportantInfoPage()));
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Visit our website', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              HapticFeedback.lightImpact();
              launchUrl(Uri.parse('https://www.millroadwinterfair.org/'));
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Contact us', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return contactUsDialog(context);
                },
              );
            },
          ),
        ),
        Expanded(
          // needed as Expanded() is relative and this needs a fixed space on larger screens
          flex: max(((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt(), 1),
          child: const SizedBox.expand(),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  launchUrl(Uri.parse('https://www.facebook.com/MillRoadWinterFair/'));
                },
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                padding: EdgeInsets.zero,
                icon: FaIcon(FontAwesomeIcons.squareFacebook, size: 40, color: Theme.of(context).colorScheme.tertiary),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  launchUrl(Uri.parse('https://x.com/millroadfair'));
                },
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                padding: EdgeInsets.zero,
                icon: FaIcon(FontAwesomeIcons.squareXTwitter, size: 40, color: Theme.of(context).colorScheme.tertiary),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  launchUrl(Uri.parse('https://www.instagram.com/millroadwinterfair/'));
                },
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                padding: EdgeInsets.zero,
                icon: FaIcon(FontAwesomeIcons.squareInstagram, size: 40, color: Theme.of(context).colorScheme.tertiary),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  launchUrl(Uri.parse('https://www.flickr.com/people/millroadwinterfair/'));
                },
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                padding: EdgeInsets.zero,
                icon: FaIcon(FontAwesomeIcons.flickr, size: 40, color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
          ),
        ),
        const Expanded(
          flex: 2,
          child: SizedBox.expand(),
        ),
        const Expanded(
          flex: 0,
          child: Divider(),
        ),
        Expanded(
          flex: 4,
          child: ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('App guide', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WelcomeScreen()));
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About the app', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              aboutDialog(context);
            },
          ),
        ),
        const Expanded(
          flex: 2,
          child: SizedBox(height: 20),
        ),
      ],
    ),
  );
}


void aboutDialog(BuildContext context) {
  PackageInfo packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );
  return showAboutDialog(
    context: context,
    applicationName: 'Mill Road\nWinter Fair',
    applicationVersion: packageInfo.version,
    applicationIcon: const MyAppIcon(),
    children: [
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.phone_android),
        title: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Android app by Alexander Berridge')),
        subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('https://theberridge.com', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))),
        onTap: () async {
          HapticFeedback.lightImpact();
          launchUrl(Uri.parse('https://theberridge.com'));
        },
      ),
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.phone_iphone),
        title: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('iPhone version by Matt Whiting')),
        subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('http://mattwhiting.com', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))),
        onTap: () async {
          HapticFeedback.lightImpact();
          launchUrl(Uri.parse('http://mattwhiting.com'));
        },
      ),
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.palette),
        title: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Illustrations by Clare McEwan')),
        subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child:
                Text('https://www.claremcewan.co.uk', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))),
        onTap: () async {
          HapticFeedback.lightImpact();
          launchUrl(Uri.parse('https://www.claremcewan.co.uk'));
        },
      ),
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.feedback),
        title: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Tell us if you like this app')),
        subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Open a feedback form', style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.tertiary))),
        onTap: () async {
          HapticFeedback.lightImpact();
          launchUrl(Uri.parse('https://www.millroadwinterfair.org/app-feedback-form/'));
        },
      ),
    ],
  );
}


Widget contactUsDialog(BuildContext theBuildContext) {
  final ScrollController emailDetailsDialogScrollController = ScrollController();
  return Dialog(
    insetPadding: EdgeInsets.all(10.0 + ((MediaQuery.of(theBuildContext).size.height.toInt() - 500) / 50).toInt()),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(300.0, 500.0);
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.all(16.0 + ((MediaQuery.of(theBuildContext).size.height.toInt() - 500) / 50).toInt()),
            child: Scrollbar(
              controller: emailDetailsDialogScrollController,
              thumbVisibility: Platform.isIOS ? false : true, // iOS has its own scrollbar style
              thickness: 4,
              radius: const Radius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SingleChildScrollView(
                  controller: emailDetailsDialogScrollController,
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('For general enquiries:', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildEmailLink('info@millroadwinterfair.org'),
                      const SizedBox(height: 15),
                      const Text('If you would like to volunteer:', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildEmailLink('volunteers@millroadwinterfair.org'),
                      const SizedBox(height: 15),
                      const Text('Enquiries regarding events or busking:', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildEmailLink('events@millroadwinterfair.org'),
                      const SizedBox(height: 15),
                      const Text('Enquiries regarding vendors:', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildEmailLink('stalls@millroadwinterfair.org'),
                      const SizedBox(height: 15),
                      const Text('Enquiries regarding the website:', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildEmailLink('it@millroadwinterfair.org'),
                      const SizedBox(height: 15),
                      const Text('Enquiries regarding the app:', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildEmailLink('app@millroadwinterfair.org'),
                      const SizedBox(height: 15),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                                style: TextStyle(fontWeight: FontWeight.bold), text: 'For any important enquiries on the day of the Fair please phone '),
                            TextSpan(
                                text: '07303\u{00A0}142689',
                                style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    final Uri phoneUri = Uri(scheme: 'tel', path: '07303 142689');
                                    if (await canLaunchUrl(phoneUri)) {
                                      await launchUrl(phoneUri);
                                    } else {
                                      throw Exception('Could not dial 07303 142689');
                                    }
                                  }),
                            const TextSpan(style: TextStyle(fontWeight: FontWeight.bold), text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Close',
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}


Widget _buildEmailLink(String email) {
  return InkWell(
    onTap: () async {
      HapticFeedback.lightImpact();
      final Uri mailUri = Uri(scheme: 'mailto', path: email);
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri);
      } else {
        throw Exception('Could not launch email client');
      }
    },
    child: Text(
      email,
      style: const TextStyle(
        decoration: TextDecoration.underline
      ),
    ),
  );
}


void showMiniPopup(BuildContext itemContext, GlobalKey? theKey, String theMessage, [Color? fgColour, Color? bgColour]) {

  fgColour ??= Theme.of(itemContext).colorScheme.secondary;
  bgColour ??= Theme.of(itemContext).colorScheme.onSecondary;

  removeMiniPopup();

  final overlay = Overlay.of(itemContext);
  final RenderBox box;
  if (theKey == null) {
    box = itemContext.findRenderObject() as RenderBox;
  } else {
    box = theKey.currentContext?.findRenderObject() as RenderBox;
  }
  final itemTopLeft = box.localToGlobal(Offset.zero);
  final itemSize = box.size;
  final screenWidth = MediaQuery.sizeOf(itemContext).width;
  final overlayW = min(max(theMessage.length / 0.25, 155.0), 230.0);
  final theStyle = TextStyle(fontSize: 13.0, decoration: TextDecoration.none, fontWeight: FontWeight.normal, color: fgColour);
  final overlayH = estimateTextHeight(text: theMessage, style:theStyle, maxWidth:overlayW, context: itemContext);
  const gap = 4.0;
  final theDuration = (theMessage.length / 25).toInt() + 2;

  // Prefer placing the box above the item, otherwise below.
  double desiredTop = itemTopLeft.dy - overlayH - gap - 8.0; // box padding
  if (desiredTop < MediaQuery.paddingOf(itemContext).top + 4) {
    desiredTop = itemTopLeft.dy + itemSize.height + gap;
  }
  // Horizontal: try to centre above the item
  double desiredLeft = itemTopLeft.dx + itemSize.width / 2 - overlayW / 2;
  if (desiredLeft < 4) desiredLeft = 4;
  if (desiredLeft + overlayW > screenWidth - 4) desiredLeft = screenWidth - overlayW - 4;
  _miniPopupOverlayEntry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: desiredLeft,
      top: desiredTop,
      child: GestureDetector( // since field may be clipped
        onTap: () {
          HapticFeedback.lightImpact();
          removeMiniPopup();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: overlayW, // wrapping boundary
          ),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColour,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: bgColour!, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Text(theMessage, softWrap: true,
              style: theStyle),
          ),
        ),
      ),
    ),
  );

  overlay.insert(_miniPopupOverlayEntry!);
  _miniPopupTimer = Timer(Duration(seconds: theDuration), () => removeMiniPopup());

}


void removeMiniPopup() {
  _miniPopupTimer?.cancel();
  _miniPopupTimer = null;
  if (_miniPopupOverlayEntry != null) {
    try {
      _miniPopupOverlayEntry!.remove();
    } catch (_) {}
    _miniPopupOverlayEntry = null;
  }
}


double estimateTextHeight({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required BuildContext context,
  int? maxLines,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    strutStyle: StrutStyle.fromTextStyle(style)
  )..layout(maxWidth: maxWidth);
  return tp.size.height;
}


class PositionedEvent {
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String name;
  final String subtitle;
  final String id;
  final bool cancelled;
  final String emoji;
  final String description;
  final LatLng latLng;
  final String imageURL;
  final bool brickAndMortar;
  final String email;
  final String website;
  final String phoneNumber;
  final bool isMusic;
  final 
  int lane;
  double top;
  double height;
  double left;
  double width;
  PositionedEvent({
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.name,
    required this.subtitle,
    required this.id,
    required this.cancelled,
    required this.emoji,
    required this.description,
    required this.latLng,
    required this.imageURL,
    required this.brickAndMortar,
    required this.email,
    required this.website,
    required this.phoneNumber,
    required this.isMusic,
    required this.lane, 
    required this.top, 
    required this.height, 
    required this.left, 
    required this.width,
  });
}


LatLng stringToLatLng(String input) {
//  debugPrint('stringToLatLng called: input=$input');
  try {
    // Split the string into latitude and longitude
    final parts = input.split(',');
    if (parts.length != 2) {
      throw const FormatException('Input string is not in "latitude,longitude" format');
    }

    // Parse the latitude and longitude
    final latitude = double.parse(parts[0].trim());
    final longitude = double.parse(parts[1].trim());
//    debugPrint('Parsed LatLng: lat=$latitude, lng=$longitude');

    // Return the LatLng object
    return LatLng(latitude, longitude);
  } catch (e) {
    debugPrint('Error parsing LatLng: $e');
    throw Exception('Error parsing LatLng from string: $e');
  }
}


int asTheCrowFlies(LatLng origin, LatLng destination) {
//  debugPrint('asTheCrowFlies called: origin=$origin, destination=$destination');

  // Constant value for converting degrees to radians (π/180)
  const p = 0.017453292519943295;
  // Alias for the cosine function for easier usage in the formula
  const c = cos;

  // Haversine formula for calculating the central angle between two points on a sphere
  var a = 0.5 -
      c((destination.latitude - origin.latitude) * p) / 2 +
      c(origin.latitude * p) * c(destination.latitude * p) * (1 - c((destination.longitude - origin.longitude) * p)) / 2;

  // Why have a fudge factor? It's a UX thing
  // Estimating distances usings straight line routes means that the estimation is inevitably shorter than the actual walking route
  // Tapping 'Get Directions' for a destination that is supposedly 600 metres away and then seeing that it's actually 900 meters away feels bad
  // The fudge factor attempts to correct for these underestimations
  const fudgeFactor = 1.33;

  // Compute the great-circle distance in metres
  // Earth's radius is approximately 6,371 km (or 12,742 km for the diameter)
  // Multiply the central angle (in radians) by Earth's diameter and convert to metres
  // Apply the fudge factor (See above)
  // Round the figure to 0 decimal places
  var distanceMetres = (((12742 * asin(sqrt(a))) * 1000) * fudgeFactor).round();
//  debugPrint('Distance calculated: $distanceMetres metres');
  return distanceMetres;
}


String convertDistanceUnits(int distanceMetres, DistanceUnits preferredDistanceUnits) {
//  debugPrint('convertDistanceUnits called: distanceMetres=$distanceMetres, preferredDistanceUnits=$preferredDistanceUnits');
  String distanceToDestination = "Distance conversion error";

  if (preferredDistanceUnits == DistanceUnits.metric) {
    if (distanceMetres <= 999) {
      distanceToDestination = '$distanceMetres m';
    } else {
      final distanceKilometresRounded = (distanceMetres / 1000).toStringAsFixed(2);
      distanceToDestination = '$distanceKilometresRounded km';
    }
  } else if (preferredDistanceUnits == DistanceUnits.imperial) {
    if (distanceMetres <= 161) {
      final distanceFeetRounded = (distanceMetres * 3.28084).toStringAsFixed(0);
      distanceToDestination = '$distanceFeetRounded ft';
    } else {
      final distanceMilesRounded = (distanceMetres / 1609.34).toStringAsFixed(2);
      distanceToDestination = '$distanceMilesRounded miles';
    }
  } else if (preferredDistanceUnits == DistanceUnits.cambridge) {
    final puntLengths = (distanceMetres / 4).toStringAsFixed(0);
    distanceToDestination = '$puntLengths punts';
  }

//  debugPrint('Distance converted: $distanceToDestination');
  return distanceToDestination;
}


String formatTime(DateTime theTime) {
  return '${theTime.hour.toString().padLeft(2,'0')}:${theTime.minute.toString().padLeft(2,'0')}';
}


String formatTimeRange(DateTime startTime, DateTime endTime) {
  return '${formatTime(startTime)}–${formatTime(endTime)}';
}

