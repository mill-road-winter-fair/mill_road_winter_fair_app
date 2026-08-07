import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';


class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late ScrollController _timetablePageScrollController;

  @override
  void initState() {
    super.initState();
    _timetablePageScrollController = ScrollController();
  }

  @override
  void dispose() {
    _timetablePageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('TimetablePage build() called');
    var bodyStyle = TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.tertiary);


    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: Scaffold(
        body: Container(width: min(MediaQuery.of(context).size.width - 8, 500),
          padding: EdgeInsets.all(4.0 + ((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt()),
          child: Scrollbar(
            controller: _timetablePageScrollController,
            thumbVisibility: Platform.isIOS ? false : true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SingleChildScrollView(
                controller: _timetablePageScrollController,
                primary: false,
                child: Column(
                  children: [
                    Text(style: bodyStyle, 'Nothing here yet'),
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
