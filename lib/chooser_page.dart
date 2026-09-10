import 'dart:ui' as ui;
import 'dart:math';
import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';


class ChooserPage extends StatefulWidget {
  const ChooserPage({
    required this.theEvents,
    required this.onOpenTimetable,
    required this.onOpenListings,
    required this.onOpenMap,
    required this.onTabSelected,
    super.key,
  });

  @override
  State<ChooserPage> createState() => _ChooserPageState();
  final List<Map<String, dynamic>> theEvents;
  final Function(bool, bool?) onOpenTimetable;
  final Function(String, String?) onOpenListings;
  final Function(int?) onOpenMap;
  final ValueChanged<int> onTabSelected;
}

class _ChooserPageState extends State<ChooserPage> with SingleTickerProviderStateMixin {
  late ScrollController _chooserPageScrollController;
  late final AnimationController _animationController;
  Timer? _idleTimer;
  int? _chosenHotspotID; // hotspot that the user tapped on, if any
  HighlightMode _highlightMode = HighlightMode.none;
  List<Hotspot> hotspots = [];
  int _lastAnimationStep = -1;
  final ValueNotifier<double> _paintPhase = ValueNotifier(0.0);
  final ValueNotifier<int> _hotspotImageVersion = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _chooserPageScrollController = ScrollController();
    if (!staticChooserPage.value) {
      _animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 6),
      )..repeat();
      _animationController.addListener(_updatePaintPhase);
    }
  }

  @override
  void dispose() {
    _chooserPageScrollController.dispose();
    if (!staticChooserPage.value) {
      _animationController
        ..dispose()
        ..removeListener(_updatePaintPhase);
    }
    _paintPhase.dispose();
    _hotspotImageVersion.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }


  void _updatePaintPhase() {
    const animationSteps = 70; // higher = smoother but more expensive
    final step = (_animationController.value * animationSteps).floor();
    if (step == _lastAnimationStep) return;
    _lastAnimationStep = step;
    _paintPhase.value = step / animationSteps;
}

  void restartAnimation() {
    _idleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _chosenHotspotID = null;
        _highlightMode = HighlightMode.idle;
      });
      if (!_animationController.isAnimating) {
        _animationController.repeat();
      }
    });
  }


  void _pauseAnimationOnPointerDown(PointerDownEvent event) {
    _animationController.stop(canceled: false);
    if (!onTest) restartAnimation();
  }


  // can only create these once we can access widget and constraints (to save repeated calculation)
  void createHotspots(double maxWidth, double maxHeight) {
    hotspots = [
      Hotspot(
        label: 'Food &\nDrink',
        labelHorizontalOffset: -0.1,
        labelVerticalOffset: 0,
        left: -0.03,
        top: 0.01,
        scale: 1.3,
        assetPath: 'assets/chooserPage/foodDrink.png',
        theTap: () => widget.onOpenListings('all', 'food'),
      ),
      Hotspot(
        label: 'Music',
        labelHorizontalOffset: -0.04,
        labelVerticalOffset: 0.03,
        left: 0.66,
        top: -0.005,
        scale: 1.22,
        assetPath: 'assets/chooserPage/music.png',
        theTap: () => widget.onOpenTimetable(false, true),
      ),
      Hotspot(label: 'Children’s', 
        labelHorizontalOffset: -0.02,
        labelVerticalOffset: 0,
        left: 0.35, 
        top: 0.13, 
        scale: 1.25,
        assetPath: 'assets/chooserPage/childrens.png', 
        theTap: () => widget.onOpenListings('all', 'performanceChildrens'),
      ),
      Hotspot(
        label: 'Charity,\nCommunity\n& Info', 
        labelHorizontalOffset: 0,
        labelVerticalOffset: 0.07,
        left: 0, 
        top: 0.29, 
        scale: 1.25,
        assetPath: 'assets/chooserPage/charityCommunityInfo.png', 
        theTap: () => widget.onOpenListings('all', 'charityCommunityInfo'),
      ),
      Hotspot(
        label: 'Visit &\nExperience',
        labelHorizontalOffset: 0.13,
        labelVerticalOffset: 0.02,
        left: 0.19,
        top: 0.53,
        scale: 1.3,
        assetPath: 'assets/chooserPage/visitExperience.png',
        theTap: () => widget.onOpenListings('all', 'visitExperience'),
      ),
      Hotspot(
        label: 'Services',
        labelHorizontalOffset: 0,
        labelVerticalOffset: 0.1,
        left: 0,
        top: 0.69,
        scale: 1.03,
        assetPath: 'assets/chooserPage/services.png',
        theTap: () => widget.onOpenListings('all', 'service'),
      ),
      Hotspot(
        label: 'Shopping ',
        labelHorizontalOffset: -0.05,
        labelVerticalOffset: 0.04,
        left: 0.65,
        top: 0.31,
        scale: 1.35,
        assetPath: 'assets/chooserPage/shopping.png',
        theTap: () => widget.onOpenListings('all', 'shopping'),
      ),
      Hotspot(
        label: 'Nearby',
        labelHorizontalOffset: 0.02,
        labelVerticalOffset: 0.08,
        left: 0.57,
        top: 0.675,
        scale: 1.2,
        assetPath: 'assets/chooserPage/nearby.png',
        theTap: () => widget.onOpenMap(10),
      ),
    ];
    _loadHotspotImages();
  }

  Future<void> _loadHotspotImages() async {
    for (final hotspot in hotspots) {
      if (hotspot.image != null) continue;
      final imageProvider = AssetImage(hotspot.assetPath);
      final config = const ImageConfiguration();
      final stream = imageProvider.resolve(config);
      final completer = Completer<ui.Image>();
      final listener = ImageStreamListener((info, _) => completer.complete(info.image),
          onError: (Object error, StackTrace? stackTrace) => completer.completeError(error, stackTrace));
      stream.addListener(listener);

      try {
        final image = await completer.future;
        if (!mounted) return;
        setState(() {
          hotspot.image = image;
          _hotspotImageVersion.value++;
        });
      } catch (_) {
        // During hot reload or missing assets, the glow can fall back to the radial gradient.
      } finally {
        stream.removeListener(listener);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    debugPrint('ChooserPage build() called');

    if (!staticChooserPage.value && _highlightMode == HighlightMode.idle && !_animationController.isAnimating) {
      _animationController.repeat();
    }
    if (!staticChooserPage.value && (_idleTimer == null || !_idleTimer!.isActive) && _highlightMode == HighlightMode.idle && !_animationController.isAnimating) {
      restartAnimation();
    }
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<double>(
      valueListenable: _paintPhase,
      builder: (context, phase, child) {
        return Listener(
          onPointerDown: (!staticChooserPage.value) ? _pauseAnimationOnPointerDown : null,
          behavior: HitTestBehavior.translucent,
          child: FairScaffold(
            appBarTitle: 'Welcome!',
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
            body: ValueListenableBuilder<bool>(
              valueListenable: staticChooserPage,
              builder: (context, name, child) {
                return RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (hotspots.isEmpty) createHotspots(constraints.maxWidth, constraints.maxHeight);
                      final visibleCount = min(3, hotspots.length);
                      final orderedHotspotIndices = List<int>.generate(hotspots.length, (index) => index)
                        ..sort((a, b) {
                          final aOpacity = _highlightMode == HighlightMode.selected && _chosenHotspotID == a
                              ? 1.0
                              : hotspotImageOpacityForPhase(b, phase, visibleCount: visibleCount);
                          final bOpacity = _highlightMode == HighlightMode.selected && _chosenHotspotID == b
                              ? 1.0
                              : hotspotImageOpacityForPhase(b, phase, visibleCount: visibleCount);
                          return aOpacity.compareTo(bOpacity);
                        });
                      final layout = List<_HotspotLayout>.generate(
                        hotspots.length,
                        (index) {
                          final hotspot = hotspots[index];
                          final size = hotspot.displaySize();
                          return _HotspotLayout(
                            index: index,
                            left: hotspot.left * constraints.maxWidth,
                            top: hotspot.top * constraints.maxHeight,
                            size: size,
                            labelHorizontalOffset: hotspot.labelHorizontalOffset * constraints.maxWidth,
                            labelVerticalOffset: hotspot.labelVerticalOffset * constraints.maxHeight,
                          );
                        },
                        growable: false,
                      );
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('assets/chooserPage/chooserPage_background.jpg', fit: BoxFit.fill),
                          Positioned.fill(
                            left: 0, right: 0, top: 0, bottom: 0,
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                              child: Container(color: Colors.white.withAlpha(100)),
                            ),
                          ),
                          Positioned(
                            top: 20, left: 0, right: 0, 
                            child: Align(alignment: AlignmentGeometry.center, 
                              child: SimpleShadow(
                                opacity: 1,
                                color: Colors.white,
                                sigma: 6.0,
                                offset: const Offset(0, 0),
                                child: Image.asset(
                                  'assets/chooserPage/MRWF_logo_transparent.png',
                                  fit: BoxFit.contain,
                                  width: constraints.maxWidth * 0.55,
                                ),
                              ),
                            ),
                          ),
                          for (final item in layout.where((entry) => orderedHotspotIndices.contains(entry.index)))
                            Positioned(
                              left: item.left,
                              top: item.top,
                              width: item.size.width,
                              height: item.size.height,
                              child: IgnorePointer(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SimpleShadow(
                                      opacity: (staticChooserPage.value) ? 1 : hotspotLabelOpacityForPhase(item.index, phase, visibleCount: visibleCount),
                                      color: Colors.white,
                                      sigma: 6.0,
                                      offset: const Offset(0, 0),
                                      child: Image.asset(
                                        hotspots[item.index].assetPath,
                                        fit: BoxFit.contain,
                                        width: item.size.width,
                                        height: item.size.height,
                                      ),
                                    ),
                                    Positioned(
                                      left: item.labelHorizontalOffset,
                                      width: item.size.width - item.labelHorizontalOffset,
                                      top: item.labelVerticalOffset, 
                                      height: item.size.height - item.labelVerticalOffset,
                                      child: Opacity(
                                        opacity: (staticChooserPage.value || (_highlightMode == HighlightMode.selected && _chosenHotspotID == item.index))
                                            ? 1.0
                                            : hotspotLabelOpacityForPhase(item.index, phase, visibleCount: visibleCount),
                                        child: Container(
                                          alignment: AlignmentGeometry.center,
                                          padding: EdgeInsets.symmetric(horizontal: 2),
                                          child: AutoSizeText(
                                            hotspots[item.index].label,
                                            textAlign: TextAlign.center,
                                            softWrap: false,
                                            overflow: TextOverflow.visible,
                                            style: TextStyle(
                                              fontSize: 27,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 0.9,
                                              leadingDistribution: TextLeadingDistribution.even,
                                              shadows: [
                                                Shadow(blurRadius: 4, color: colorScheme.primary),
                                                Shadow(blurRadius: 16, color: colorScheme.primary),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          for (final item in layout)
                            Positioned(
                              left: item.left,
                              top: item.top,
                              width: item.size.width,
                              height: item.size.height,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  _idleTimer?.cancel();
                                  debugPrint('Selected ${item.index}');
                                  setState(() {
                                    _highlightMode = HighlightMode.selected;
                                    _chosenHotspotID = item.index;
                                  });
                                  _idleTimer?.cancel();
                                  if (!staticChooserPage.value) _animationController.stop(canceled: false);
                                  hotspots[item.index].theTap();
                                },
                                child: const SizedBox.expand(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              }
            ),
          ),
        );
      },
    );
  }
}


enum HighlightMode {
  none,
  idle,
  selected,
}


double hotspotImageOpacityForPhase(int index, double progress, {required int visibleCount}) {
  if (visibleCount <= 1) return 1.0;
  final slot = index % visibleCount;
  final normalized = (progress + (slot / visibleCount)) % 1.0;
  final wave = 0.5 + (0.5 * cos(2 * pi * normalized));
  final opacity = 0.5 + (0.5 * wave);
  return opacity.clamp(0.5, 1.0);
}

double hotspotLabelOpacityForPhase(int index, double progress, {required int visibleCount}) {
  if (visibleCount <= 1) return 1.0;
  final slot = index % visibleCount;
  final normalized = (progress + (slot / visibleCount)) % 1.0;
  final wave = 0.5 + (0.5 * cos(2 * pi * normalized));
  final opacity = 0.0 + (1.0 * wave);
  return opacity.clamp(0.0, 1.0);
}


class _HotspotLayout {
  const _HotspotLayout({
    required this.index,
    required this.left,
    required this.top,
    required this.size,
    required this.labelVerticalOffset,
    required this.labelHorizontalOffset,
  });

  final int index;
  final double left;
  final double top;
  final Size size;
  final double labelVerticalOffset;
  final double labelHorizontalOffset;
}

class Hotspot {
  final String label;
  final String assetPath;
  // Coordinates are fractions of image size (0.0-1.0)
  final double left;
  final double top;
  final double scale;
  ui.Image? image;
  final void Function() theTap;
  final double labelVerticalOffset;
  final double labelHorizontalOffset;

  Hotspot({
    required this.label,
    required this.assetPath,
    required this.left,
    required this.top,
    required this.scale,
    required this.theTap,
    required this.labelVerticalOffset,
    required this.labelHorizontalOffset,
  });

  Size displaySize() {
    final width = (image?.width.toDouble() ?? 160.0) * scale;
    final height = (image?.height.toDouble() ?? 220.0) * scale;
    return Size(width, height);
  }

  Rect scaled(Size size) {
    final renderedSize = displaySize();
    return Rect.fromLTWH(
      left * size.width,
      top * size.height,
      renderedSize.width,
      renderedSize.height,
    );
  }
}
