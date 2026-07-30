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
  late final AnimationController _animationController;
  Timer? _idleTimer;
  final List<Hotspot> hotspots = [
    Hotspot(label: 'Food & Drink', left: 0, top: 0.197, width: 0.5, height: 0.152),
    Hotspot(label: 'Music', left: 0.548, top: 0.287, width: 0.451, height: 0.144),
    Hotspot(label: 'Events', left: 0, top: 0.366, width: 0.455, height: 0.19),
    Hotspot(label: 'Shopping', left: 0.583, top: 0.49, width: 0.416, height: 0.213),
    Hotspot(label: 'Children’s', left: 0, top: 0.598, width: 0.437, height: 0.214),
    Hotspot(label: 'Nearby', left: 0.666, top: 0.703, width: 0.333, height: 0.171),
    Hotspot(label: 'Services', left: 0, top: 0.881, width: 0.409, height: 0.118),
    Hotspot(label: 'Info', left: 0.668, top: 0.881, width: 0.331, height: 0.118),
  ];
  int? _chosenHotspotID; // hotspot that the user tapped on, if any
  HighlightMode _highlightMode = HighlightMode.idle;
  

  @override
  void initState() {
    super.initState();
    _chooserPageScrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: hotspots.length * 2),
    )..repeat();
    _animationController.repeat();
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
    if (_highlightMode == HighlightMode.idle) setState(() { _highlightMode = HighlightMode.none; });
    _animationController.stop();
    _idleTimer = Timer(
      const Duration(seconds: 5),
      () {
        setState(() { _highlightMode == HighlightMode.idle; });
        _animationController.repeat();
      },
    );
  }


  Future<bool> chooseDialog(BuildContext theBuildContext, String theChoice) async {
    const textStyle = TextStyle(fontSize: 18);
    const titleStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
    bool cancelled = false;
    await showDialog(
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
                      Text(style: titleStyle, 'Save this choice?'),
                      Text(style: textStyle, 'The app can remember this choice so that $theChoice always appears when you open it.'),
                      Text(style: textStyle, 'You won’t be asked again, but can always change this from Settings.'),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, spacing: 12, children: [
                        TextButton(
                          style: ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsetsGeometry.symmetric(horizontal: 0))),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            cancelled = true;
                            Navigator.pop(context);
                          },
                          child: Text('Cancel', style: textStyle.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                        ),
                        Spacer(),
                        TextButton(
                          style: ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsetsGeometry.symmetric(horizontal: 0))),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Text('Don’t save', style: textStyle.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                        ),
                        TextButton(
                          style: ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsetsGeometry.symmetric(horizontal: 0))),
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
    return cancelled;
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
                  Positioned(
                    left: 0.16 * constraints.maxWidth, 
                    top: 0.03 * constraints.maxHeight, 
                    width: 0.7 * constraints.maxWidth, 
                    height: 0.105 * constraints.maxHeight, 
                    child: Image(image: AssetImage('assets/MRWF25_leaflet_banner.png'), width: 180)),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: HotspotPainter(
                          hotspots: hotspots,
                          mode: _highlightMode,
                          chosenHotspotID: _chosenHotspotID,
                          animation: _animationController,
                        ),
                      ),
                    ),
                  ),
                  for (int i=0; i<hotspots.length; i++)
                    Positioned(
                      left: hotspots[i].left * constraints.maxWidth,
                      top: hotspots[i].top * constraints.maxHeight,
                      width: hotspots[i].width * constraints.maxWidth,
                      height: hotspots[i].height * constraints.maxHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          debugPrint('Selected $i');
                          _animationController.stop();
                          setState(() {
                            _highlightMode = HighlightMode.selected;
                            _chosenHotspotID = i;
                          });
                          final cancelled = await chooseDialog(context, hotspots[i].label);
                          debugPrint('cancelled=$cancelled');
                          if (cancelled) {
                            setState(() {
                              _chosenHotspotID = null;
                              _highlightMode = HighlightMode.none;
                            });
                            _idleTimer = Timer(const Duration(seconds: 2), () {
                              setState(() {
                                _chosenHotspotID = null;
                                _highlightMode = HighlightMode.idle;
                              });
                              _animationController.repeat();
                            });
                          }
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


enum HighlightMode {
  none,
  idle,
  selected,
}


class Hotspot {

  final String label;
  // Coordinates are fractions of image size (0.0 - 1.0)
  final double left;
  final double top;
  final double width;
  final double height;

  const Hotspot({
    required this.label,
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
    required this.mode,
    required this.chosenHotspotID,
    required this.animation,
  }) : super(repaint: animation);

  final List<Hotspot> hotspots;
  final HighlightMode mode;
  final int? chosenHotspotID;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    switch (mode) {
      case HighlightMode.none:
        return;
      case HighlightMode.selected:
        _paintHotspot(canvas, size, hotspots[chosenHotspotID!], 1.0);
        return;
      case HighlightMode.idle:
        break;
    }
    final count = hotspots.length;
    final position = animation.value * count;
    final current = position.floor() % count;
    final next = (current + 1) % count;
    final t = position - current;
    final fadeOut = 1.0 - Curves.easeInOut.transform(t);
    final fadeIn = Curves.easeInOut.transform(t);
    _paintHotspot(canvas, size, hotspots[current], fadeOut);
    _paintHotspot(canvas, size, hotspots[next], fadeIn);
  }


  void _paintHotspot(Canvas canvas, Size size, Hotspot hotspot, double opacity) {
    if (opacity <= 0.001) return;
    final rect = hotspot.scaled(size);
    _drawGlow(canvas, rect, opacity);
    _drawLabel(canvas, rect, hotspot.label, opacity);
  }


  void _drawGlow(Canvas canvas, Rect rect, double opacity) {
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


  void _drawLabel(Canvas canvas, Rect rect, String text, double opacity) {
    double fontSize = min(rect.height, 32);
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
bool shouldRepaint(covariant HotspotPainter oldDelegate) {
  return oldDelegate.mode != mode || oldDelegate.chosenHotspotID != chosenHotspotID;
}
}