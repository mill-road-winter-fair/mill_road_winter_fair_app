import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';


class TimetablePage extends StatefulWidget {
  const TimetablePage({
    super.key,
    required this.onTabSelected,
  });

  @override
  State<TimetablePage> createState() => _TimetablePageState();
  final ValueChanged<int> onTabSelected;
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
    return FairScaffold(
      appBarTitle: "Timetable",
      currentTab: 2,
      onTabSelected: widget.onTabSelected,
      appBarActions: [
      ],
      body: Scrollbar(
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
    );
  }
}
