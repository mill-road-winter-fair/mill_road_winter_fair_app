import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/welcome_screen.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';

OverlayEntry? _miniPopupOverlayEntry; // widget that floats over a given widget as a 'tooltip'
Timer? _miniPopupTimer; // times how long the above stays on screen

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
              final navigatorContext = Navigator.of(context).context; // parent context (above the drawer)
              Navigator.pop(context);
              Navigator.push(navigatorContext, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
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
              final navigatorContext = Navigator.of(context).context; // parent context (above the drawer)
              Navigator.pop(context);
              Navigator.push(navigatorContext, MaterialPageRoute(builder: (context) => const ImportantInfoPage()));
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
              Navigator.pop(context);
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
              final navigatorContext = Navigator.of(context).context; // parent context (above the drawer)
              Navigator.pop(context);
              showDialog(
                context: navigatorContext,
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
                  Navigator.pop(context);
                  launchUrl(Uri.parse('https://www.facebook.com/MillRoadWinterFair/'));
                },
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                padding: EdgeInsets.zero,
                icon: FaIcon(FontAwesomeIcons.squareFacebook, size: 40, color: Theme.of(context).colorScheme.tertiary),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  launchUrl(Uri.parse('https://x.com/millroadfair'));
                },
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                padding: EdgeInsets.zero,
                icon: FaIcon(FontAwesomeIcons.squareXTwitter, size: 40, color: Theme.of(context).colorScheme.tertiary),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  launchUrl(Uri.parse('https://www.instagram.com/millroadwinterfair/'));
                },
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                padding: EdgeInsets.zero,
                icon: FaIcon(FontAwesomeIcons.squareInstagram, size: 40, color: Theme.of(context).colorScheme.tertiary),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
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
              final navigatorContext = Navigator.of(context).context; // parent context (above the drawer)
              Navigator.pop(context);
              Navigator.push(navigatorContext, MaterialPageRoute(builder: (context) => const SettingsPage()));
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
              final navigatorContext = Navigator.of(context).context; // parent context (above the drawer)
              Navigator.pop(context);
              Navigator.pushReplacement(navigatorContext, MaterialPageRoute(builder: (context) => const WelcomeScreen()));
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: ListTile(
            leading: Icon((Platform.isIOS) ? Icons.ios_share : Icons.share),
            title: const Text('Share this app', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              HapticFeedback.lightImpact();
              final navigatorContext = Navigator.of(context).context; // parent context (above the drawer)
              Navigator.pop(context);
              displayAppShareDialog(navigatorContext);
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About this app', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              HapticFeedback.lightImpact();
              final navigatorContext = Navigator.of(context).context; // parent context (above the drawer)
              Navigator.pop(context);
              aboutDialog(navigatorContext);
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


void displayAppShareDialog(BuildContext itemContext) async {

  final colorScheme = Theme.of(itemContext).colorScheme;

  await showDialog(
    context: itemContext,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 24), // margin from screen edges
        shape: RoundedRectangleBorder(side: BorderSide(color: colorScheme.onSecondary, width: 0.5), borderRadius: BorderRadius.circular(12)),
        backgroundColor: colorScheme.surfaceContainerLowest,
        shadowColor: colorScheme.surfaceDim,
        elevation: 3,
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, spacing: 8, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold), 'Share this app'),
              Text(style: TextStyle(fontSize: 14.0),
                  'This QR code links to a web page allowing someone to install the iOS or Android version of this app.'),
              Text(style: TextStyle(fontSize: 14.0),
                  'Or tap ‘Share via message’ to send this link on to them via your choice of messaging app.'),
              Align(alignment: AlignmentGeometry.center, child: Image.asset('assets/www.millroadwinterfair.org_mrwf-app.QR.png', width: 150, height: 150)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(dialogContext).pop();
                    shareApp(itemContext, 'I’m sharing the Mill Road Winter Fair app with you. Get it here for iOS and Android https://www.millroadwinterfair.org/mrwf-app/');
                  },
                  child: Text('Share via message', style: TextStyle(color: Theme.of(itemContext).colorScheme.tertiary)),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Close', style: TextStyle(color: Theme.of(itemContext).colorScheme.tertiary)),
                ),
              ]),
            ]),
          ),
        ),
      );
    }
  );

}


void shareApp(BuildContext context, String msgText) async {
  final params = ShareParams(
    text: msgText,
    title: 'Share the app',
    //uri: Uri.parse('https://www.millroadwinterfair.org/mrwf-app/'), // can't have this and text
  );
  try {
    await SharePlus.instance.share(params);
  } catch (e) {
    debugPrint('shareApp error launching SharePlus::\n$e');
    if (context.mounted) {
      Fluttertoast.showToast(
        msg: 'Couldn’t launch share sheet. Please try again later',
        gravity: ToastGravity.CENTER,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
        fontSize: 16,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 4,
      );
    }
  }
}


void aboutDialog(BuildContext context) async {

  PackageInfo packageInfo = PackageInfo( // fallback
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );
  try {
    packageInfo = await PackageInfo.fromPlatform().timeout(const Duration(milliseconds: 200), onTimeout: () => packageInfo);
  } catch (e) {
    debugPrint('aboutDialog: couldn’t get PackageInfo.fromPlatform:\n$e');
  }

  if (!context.mounted) return;

  final inflater = (MediaQuery.of(context).size.height.toInt() - 600).clamp(0, 250) / 50;
  final colorScheme = Theme.of(context).colorScheme;
  final textStyle = TextStyle(fontSize: 13.0 + inflater / 3);
  final linkStyle = TextStyle(fontSize: 12.5 + inflater / 3, decoration: TextDecoration.underline, decorationColor: colorScheme.tertiary, color: colorScheme.tertiary);
  final ScrollController aboutDialogScrollController = ScrollController();

  if (context.mounted) {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.all(4.0 + inflater * 2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.clamp(350.0, 400.0);
              return Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.fromLTRB(16.0 + inflater * 2, 20, 10, 6),
                child: Scrollbar(
                  controller: aboutDialogScrollController,
                  thumbVisibility: Platform.isIOS ? false : true, // iOS has its own scrollbar style
                  thickness: 4,
                  radius: const Radius.circular(8),
                  child: SingleChildScrollView(
                    controller: aboutDialogScrollController,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity(horizontal: -4 + inflater, vertical: -4),
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(borderRadius: BorderRadius.circular(6.0), child: Image.asset('assets/icons/icon.png', width: 28, fit: BoxFit.contain)),
                        title: Text(fairName, style: textStyle.copyWith(fontSize: 18 + inflater / 3, fontWeight: FontWeight.bold)),
                        subtitle: Text('v${packageInfo.version}', style: textStyle),
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity(horizontal: -3 + inflater, vertical: -4),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.phone_android, size: 28),
                        title: Text('Android app by Alexander Berridge', style: textStyle),
                        subtitle: Text('https://theberridge.com', style: linkStyle),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse('https://theberridge.com'));
                        },
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity(horizontal: -3 + inflater, vertical: -4),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.phone_iphone, size: 28),
                        title: Text('iPhone version by Matt Whiting', style: textStyle),
                        subtitle: Text('http://mattwhiting.com', style: linkStyle),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse('http://mattwhiting.com'));
                        },
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity(horizontal: -3 + inflater, vertical: -4),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule, size: 28),
                        title: Text('Timetable view based on Clashfinder Pal by permission of the author', style: textStyle),
                        subtitle: Text('https://linktr.ee/cfpal', style: linkStyle),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse('https://linktr.ee/cfpal'));
                        },
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity(horizontal: -3 + inflater, vertical: -4),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.palette_outlined, size: 26),
                        title: Text('Illustrations by Clare McEwan', style: textStyle),
                        subtitle: Text('https://www.claremcewan.co.uk', style: linkStyle),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse('https://www.claremcewan.co.uk'));
                        },
                      ),
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity(horizontal: -3 + inflater, vertical: -4),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.feedback_outlined, size: 26),
                        title: Text('Tell us if you like this app', style: textStyle),
                        subtitle: Text('Open a feedback form', style: linkStyle),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          launchUrl(Uri.parse('https://www.millroadwinterfair.org/app-feedback-form/'));
                        },
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.end, spacing: 10, children: [
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(dialogContext).pop();
                            showLicensePage(context: context);
                          },
                          child: Text('View licences', style: TextStyle(color: colorScheme.tertiary)),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text('Close', style: TextStyle(color: colorScheme.tertiary)),
                        ),
                      ]),
                    ]
                    ),
                  )
                )
              );
            }
          )
        );
      }
    );
  }
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
                                    HapticFeedback.lightImpact();
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


