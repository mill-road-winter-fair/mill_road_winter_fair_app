import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';


class ChooserPage extends StatefulWidget {
  const ChooserPage({
    required this.theEvents,
    required this.onOpenTimetable,
    required this.onOpenListings,
    required this.onTabSelected,
    super.key,
  });

  @override
  State<ChooserPage> createState() => _ChooserPageState();
  final List<Map<String, dynamic>> theEvents;
  final Function(bool, bool?) onOpenTimetable;
  final Function(String, String?) onOpenListings;
  final ValueChanged<int> onTabSelected;
}

class _ChooserPageState extends State<ChooserPage> {
  late ScrollController _chooserPageScrollController;

  @override
  void initState() {
    super.initState();
    _chooserPageScrollController = ScrollController();
  }

  @override
  void dispose() {
    _chooserPageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ChooserPage build() called');
    var bodyStyle = TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.tertiary);
    return FairScaffold(
      appBarTitle: "Welcome",
      currentTab: 0,
      onTabSelected: widget.onTabSelected,
      appBarActions: [
        IconButton(
          icon: const ImageIcon(AssetImage('assets/icons/iconTransparent.png')),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
          },
        ),
      ],
      body: Scrollbar(
        controller: _chooserPageScrollController,
        thumbVisibility: Platform.isIOS ? false : true,
        thickness: 4,
        radius: const Radius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            controller: _chooserPageScrollController,
            primary: false,
            child: Text.rich(TextSpan(children: [
                TextSpan(style: bodyStyle, text: 'Test links for plumbing:\n\n'),
                TextSpan(style: bodyStyle, text: '• Timetable (music only)\n', recognizer: TapGestureRecognizer()..onTap = () => widget.onOpenTimetable(false, true)),
                TextSpan(style: bodyStyle, text: '• Timetable (all but music)\n', recognizer: TapGestureRecognizer()..onTap = () => widget.onOpenTimetable(false, false)),
                TextSpan(style: bodyStyle, text: '• Timetable (music on now or soon)\n', recognizer: TapGestureRecognizer()..onTap = () => widget.onOpenTimetable(true, true)),
                TextSpan(style: bodyStyle, text: '• Timetable (all but music on now or soon)\n', recognizer: TapGestureRecognizer()..onTap = () => widget.onOpenTimetable(true, false)),
                TextSpan(style: bodyStyle, text: '• Listings (music only)\n', recognizer: TapGestureRecognizer()..onTap = () => widget.onOpenListings('all', 'performanceMusic')),
                TextSpan(style: bodyStyle, text: '• Listings (other performances only)\n', recognizer: TapGestureRecognizer()..onTap = () => widget.onOpenListings('all', 'performanceOther')),
                TextSpan(style: bodyStyle, text: '• Listings (children’s only)\n', recognizer: TapGestureRecognizer()..onTap = () => widget.onOpenListings('all', 'performanceChildrens')),
                TextSpan(style: bodyStyle, text: '• Favourite listings (music only)\n', recognizer: TapGestureRecognizer()..onTap = () => widget.onOpenListings('favourite', 'performanceMusic')),
              ]),
            ), // Add event details here
          ),
        ),
      ),
    );
  }
}
