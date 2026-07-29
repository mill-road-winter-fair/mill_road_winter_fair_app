import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';


class ChooserPage extends StatefulWidget {
  const ChooserPage({required this.onChangeTitle, super.key});
  final void Function(String)? onChangeTitle;
  @override
  State<ChooserPage> createState() => _ChooserPageState();
}

class _ChooserPageState extends State<ChooserPage> with SingleTickerProviderStateMixin {
  late ScrollController _chooserPageScrollController;
  Timer? _idleTimer;
  final List<Hotspot> hotspots = [
    Hotspot(id: 'Food & Drink', left: 0, top: 0.197, width: 0.5, height: 0.152),
    Hotspot(id: 'Music', left: 0.548, top: 0.287, width: 0.451, height: 0.144),
    Hotspot(id: 'Events', left: 0, top: 0.366, width: 0.455, height: 0.19),
    Hotspot(id: 'Shopping', left: 0.583, top: 0.49, width: 0.416, height: 0.213),
    Hotspot(id: 'Children’s', left: 0, top: 0.598, width: 0.437, height: 0.214),
    Hotspot(id: 'Nearby', left: 0.666, top: 0.703, width: 0.333, height: 0.171),
    Hotspot(id: 'Services', left: 0, top: 0.881, width: 0.409, height: 0.118),
    Hotspot(id: 'Info', left: 0.668, top: 0.881, width: 0.331, height: 0.118),
  ];
  int _activeHotspot = 0; // the hotspot that is currently glowing
  String? _chosenHotspotID; // ID of the hotspot that the user tapped on
  bool _idleMode = true; // kicks in when user hasn't done anything for a period
  late final AnimationController _animationController;
  final highlightedHotspots = <String>{
    'Info',
    'Music',
    'Food & Drink',
    'Events',
    'Services',
    'Nearby',
    'Shopping',
    'Children’s'
  };


  @override
  void initState() {
    super.initState();
    _chooserPageScrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _activeHotspot = (_activeHotspot + 1) % hotspots.length;
        });
        _animationController.forward(from: 0);
      }
    });
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChangeTitle?.call('Welcome!'));
  }


  @override
  void dispose() {
    _chooserPageScrollController.dispose();
    _animationController.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }


  void userInteraction() {
    _idleTimer?.cancel();
    if (_idleMode) setState(() { _idleMode = false; });
    _animationController.stop();
    _idleTimer = Timer(
      const Duration(seconds: 5),
      () {
        setState(() { _idleMode = true; });
        _animationController.forward(from: 0);
      },
    );
  }


  void chooseDialog(BuildContext theBuildContext, String theChoice) {
    const textStyle = TextStyle(fontSize: 18);
    const titleStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(10.0 + ((MediaQuery.of(theBuildContext).size.height.toInt() - 500) / 50).toInt()),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.clamp(300.0, 500.0);
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.all(16.0 + ((MediaQuery.of(theBuildContext).size.height.toInt() - 500) / 50).toInt()),
                  child: Column(spacing: 12,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(style: titleStyle, 'Remember this choice?'),
                          Text(style: textStyle, 'Would you like to save this choice so that $theChoice always appears when you open the app?'),
                          Row(mainAxisAlignment: MainAxisAlignment.end, spacing: 12, children: [
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              child: Text('Don’t save', style: textStyle.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              child: Text('Save', style: textStyle.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                            ),
                          ]),
                        ],
                      ),
                    ),            
                  );
            }
          )
        );
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    debugPrint('ChooserPageState build() called');
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: Scaffold(
        body: Listener(
          onPointerDown: (_) => userInteraction(),
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(fit: StackFit.expand, children: [
                  Image.asset('assets/chooserPage/chooserPage_background.png', fit: BoxFit.fill),
                  Positioned(left: 115, top: 22, child: Image(image: AssetImage('assets/MRWF25_leaflet_banner.png'), width: 180)),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: HotspotPainter(
                          hotspots: hotspots,
                          activeIndex: _activeHotspot,
                          idleMode: _idleMode,
                          animation: _animationController,
                        ),
                      ),
                    ),
                  ),
                  for (final hotspot in hotspots)
                    Positioned(
                      left: hotspot.left * constraints.maxWidth,
                      top: hotspot.top * constraints.maxHeight,
                      width: hotspot.width * constraints.maxWidth,
                      height: hotspot.height * constraints.maxHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _chosenHotspotID = hotspot.id;
                          userInteraction();
                          chooseDialog(context, _chosenHotspotID!);
                          debugPrint('Selected $_chosenHotspotID');
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


class Hotspot {

  final String id;
  // Coordinates are fractions of image size (0.0 - 1.0)
  final double left;
  final double top;
  final double width;
  final double height;

  const Hotspot({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  Rect scaled(Size size) {
    return Rect.fromLTWH(
      left * size.width,
      top * size.height,
      width * size.width,
      height * size.height,
    );
  }
}


class HotspotPainter extends CustomPainter {

  HotspotPainter({
    required this.hotspots,
    required this.activeIndex,
    required this.idleMode,
    required this.animation,
  }) : super(repaint: animation);

  final List<Hotspot> hotspots;
  final int activeIndex;
  final bool idleMode;
  final Animation<double> animation;

  @override
  void paint(
      Canvas canvas,
      Size size,
  ) {
    if (!idleMode) return;
    final hotspot = hotspots[activeIndex];
    final rect = hotspot.scaled(size);
    final fade = sin(animation.value * pi);
    _drawGlow(canvas, rect, fade);
    _drawLabel(canvas, rect, hotspot.id, fade);
  }

  void _drawGlow(
      Canvas canvas,
      Rect rect,
      double opacity,
  ) {

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        rect.width / 2,
        [
          Colors.red.withValues(alpha: opacity),
          Colors.red.withValues(alpha: 0.25 * opacity),
          Colors.transparent,
        ],
        [0, 0.8, 1.0],
      );
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.scale(1.0, rect.height / rect.width);
    canvas.drawCircle(Offset.zero, rect.width / 2, paint);
    canvas.restore();
  }



  void _drawLabel(
      Canvas canvas,
      Rect rect,
      String text,
      double opacity,
  ) {

    double fontSize = rect.height;
    TextPainter? painter;
    while (fontSize > 5) {
      painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: opacity),
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black.withValues(alpha: opacity)),
              Shadow(blurRadius: 16, color: Colors.black.withValues(alpha: opacity)),
            ],
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      if (painter.width <= rect.width * 0.9 && painter.height <= rect.height * 0.8) break;
      fontSize--;
    }
    if (painter == null) return;
    painter.paint(canvas, Offset(rect.center.dx - painter.width / 2, rect.center.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(
      covariant HotspotPainter oldDelegate,
  ) {

    return oldDelegate.activeIndex != activeIndex ||
        oldDelegate.idleMode != idleMode;

  }
}