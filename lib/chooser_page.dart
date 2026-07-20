import 'dart:io';
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
    var bodyStyle = TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold);


    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: Scaffold(
        body: Container(width: double.infinity, height: double.infinity,
          decoration: BoxDecoration(image: const DecorationImage(fit: BoxFit.fill, image: AssetImage('assets/chooserPage/chooserPage_background.png'))),
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
                    SizedBox(height: 6),
                    Image(image: AssetImage('assets/MRWF25_leaflet_banner.png'), width: 180),
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
