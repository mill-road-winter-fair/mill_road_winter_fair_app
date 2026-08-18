import 'dart:ui' as ui;
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
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

class _ChooserPageState extends State<ChooserPage> with SingleTickerProviderStateMixin {
  late ScrollController _chooserPageScrollController;
  late final AnimationController _animationController;
  Timer? _idleTimer;
  final List<Hotspot> hotspots = [
    Hotspot(label: 'Food & Drink', left: 0, top: 0.197, width: 0.5, height: 0.152),
    Hotspot(label: 'Music', left: 0.548, top: 0.287, width: 0.451, height: 0.144),
    Hotspot(label: 'Events and\nPerformances', left: 0, top: 0.366, width: 0.455, height: 0.19),
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
      duration: Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _chooserPageScrollController.dispose();
    _animationController.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }


  Future<bool> chooseDialog(BuildContext theBuildContext, String theChoice) async {
    const textStyle = TextStyle(fontSize: 18);
    const titleStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
    bool cancelled = false;
    bool savingchoice = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            return Dialog(
              insetPadding: EdgeInsets.all(10.0 + ((MediaQuery.of(theBuildContext).size.height.toInt() - 500) / 50).toInt()),
              child: LayoutBuilder(builder: (context, constraints) {
                final maxWidth = constraints.maxWidth.clamp(300.0, 500.0);
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.all(16.0 + ((MediaQuery.of(theBuildContext).size.height.toInt() - 500) / 50).toInt()),
                    child: Column(
                      spacing: 12,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(style: titleStyle, 'Save this choice?'),
                        Row(spacing: 12, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Checkbox(
                            value: savingchoice, 
                            visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                            onChanged: (bool? newValue) {
                              savingchoice = newValue!;
                              setStateDialog(() { });
                            }
                          ),
                          Expanded(child: Text(style: textStyle, 'Remember this choice so that $theChoice always appears when you open the app. '
                            'You can change this from Settings.')),
                        ]),
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
                            child: Text((savingchoice) ? 'Save and continue' : 'Continue', style: textStyle.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                );
              }),
            );
          }
        );
      }
    );
    return cancelled;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ChooserPage build() called');
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
      body: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
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
                        _idleTimer?.cancel();
                        debugPrint('Selected $i');
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
    );
  }
}


enum HighlightMode {
  none,
  idle,
  selected,
}


double hotspotOpacityForPhase(int index, double progress, {required int visibleCount}) {
  if (visibleCount <= 1) return 1.0;
  final slot = index % visibleCount;
  final normalized = (progress + (slot / visibleCount)) % 1.0;
  final wave = 0.5 + (0.5 * cos(2 * pi * normalized));
  final opacity = 0.1 + (0.9 * wave);
  return opacity.clamp(0.0, 1.0);
}


class Hotspot {
  final String label;
  // Coordinates are fractions of image size (0.0-1.0)
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


class _HotspotVisual {
  const _HotspotVisual({
    required this.rect,
    required this.glowPicture,
    required this.labelPicture,
  });
  final Rect rect;
  final ui.Picture glowPicture;
  final ui.Picture labelPicture;
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

  Size? _lastSize;
  List<_HotspotVisual>? _cachedVisuals;

  @override
  void paint(Canvas canvas, Size size) {
    switch (mode) {
      case HighlightMode.none:
        return;
      case HighlightMode.selected:
        _ensureVisuals(size);
        _paintHotspot(canvas, _cachedVisuals![chosenHotspotID!], 1.0);
        return;
      case HighlightMode.idle:
        break;
    }
    _ensureVisuals(size);
    final visibleCount = min(3, hotspots.length);
    for (var index = 0; index < _cachedVisuals!.length; index++) {
      final opacity = hotspotOpacityForPhase(index, animation.value, visibleCount: visibleCount);
      if (opacity <= 0.03) continue;
      _paintHotspot(canvas, _cachedVisuals![index], opacity);
    }
  }

  void _ensureVisuals(Size size) {
    if (_lastSize == size && _cachedVisuals != null && _cachedVisuals!.length == hotspots.length) return;
    _lastSize = size;
    _cachedVisuals = List<_HotspotVisual>.generate(
      hotspots.length,
      (index) => _buildVisual(size, hotspots[index]),
      growable: false,
    );
  }

  _HotspotVisual _buildVisual(Size size, Hotspot hotspot) {
    final rect = hotspot.scaled(size);
    final localRect = Rect.fromLTWH(0, 0, rect.width, rect.height);
    final glowRecorder = ui.PictureRecorder();
    final glowCanvas = Canvas(glowRecorder);
    _drawGlow(glowCanvas, localRect, 1.0);
    final labelRecorder = ui.PictureRecorder();
    final labelCanvas = Canvas(labelRecorder);
    _drawLabel(labelCanvas, localRect, hotspot.label, 1.0);
    return _HotspotVisual(
      rect: rect,
      glowPicture: glowRecorder.endRecording(),
      labelPicture: labelRecorder.endRecording(),
    );
  }

  void _paintHotspot(Canvas canvas, _HotspotVisual visual, double opacity) {
    if (opacity <= 0.001) return;
    canvas.save();
    canvas.translate(visual.rect.left, visual.rect.top);
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    canvas.saveLayer(Rect.fromLTWH(0, 0, visual.rect.width, visual.rect.height), paint);
    canvas.drawPicture(visual.glowPicture);
    canvas.drawPicture(visual.labelPicture);
    canvas.restore();
    canvas.restore();
  }

  void _drawGlow(Canvas canvas, Rect rect, double opacity) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        rect.width / 2,
        [
          Colors.yellow.withValues(alpha: opacity),
          Colors.yellow.withValues(alpha: 0.25 * opacity),
          Colors.transparent,
        ],
        [0, 0.6, 1.0],
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
        textAlign: TextAlign.center,
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
        maxLines: 2,
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
