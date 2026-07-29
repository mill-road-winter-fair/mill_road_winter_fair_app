import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';


class ChooserPage extends StatefulWidget {
  const ChooserPage({super.key});

  @override
  State<ChooserPage> createState() => _ChooserPageState();
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


    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: Scaffold(
        body: Container(width: min(MediaQuery.of(context).size.width - 8, 500),
          padding: EdgeInsets.all(4.0 + ((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt()),
          child: Scrollbar(
            controller: _chooserPageScrollController,
            thumbVisibility: Platform.isIOS ? false : true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SingleChildScrollView(
                controller: _chooserPageScrollController,
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
