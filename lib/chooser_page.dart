import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';


class ChooserPage extends StatefulWidget {
  const ChooserPage({
    super.key,
    required this.onTabSelected,
  });

  @override
  State<ChooserPage> createState() => _ChooserPageState();
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
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
        IconButton(
          icon: const ImageIcon(AssetImage('assets/icons/iconTransparent.png')),
          onPressed: () {
            HapticFeedback.lightImpact();
          },
        ),
      ],
      body: Scrollbar(
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
    );
  }
}
