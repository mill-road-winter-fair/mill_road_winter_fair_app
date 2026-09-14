import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';


class ChooserPage extends StatefulWidget {

  const ChooserPage({
    required this.theEvents,
    required this.onOpenTimetable,
    required this.onOpenListings,
    required this.onOpenMap,
    required this.onTabSelected,
    super.key,
  });

  final List<Map<String, dynamic>> theEvents;
  final Function(bool, bool?) onOpenTimetable;
  final Function(String, String?) onOpenListings;
  final Function(int?) onOpenMap;
  final ValueChanged<int> onTabSelected;

  @override
  State<ChooserPage> createState() => _ChooserPageState();

}


class _ChooserPageState extends State<ChooserPage> with TickerProviderStateMixin {

  AnimationController? _animationController;
  AnimationController? _initialEntranceController;
  Timer? _idleTimer;
  int? _chosenHotspotID;
  List<Hotspot> hotspots = [];
  Future<void>? _hotspotsFuture;

  static const int _idleAnimationSteps = 60; // throttling: larger is smoother but dearer
  static const int _entranceAnimationSteps = 300; // throttling: larger is smoother but dearer
  static const int _idleAnimationPeriod = 6; // for an entire cycle
  static const int _entranceAnimationPeriod = 10; // from just background to all icons
  static const int _restartIdleAnimationPeriod = 3; // after how much inactivity to start again
  final ValueNotifier<double> _paintPhase = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _entranceProgress = ValueNotifier<double>(0.0);
  int _lastPaintStep = -1;
  int _lastEntranceStep = -1;
  bool _initialEntranceStarted = false;
  bool _initialEntranceComplete = false;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: _idleAnimationPeriod))
      ..addListener(_updatePaintPhase);
    _initialEntranceController = AnimationController(vsync: this, duration: const Duration(seconds: _entranceAnimationPeriod))
      ..addListener(_updateEntranceProgress)
      ..addStatusListener(_entranceStatusChanged);
    staticChooserPage.addListener(_staticChooserPageChanged);
    if (staticChooserPage.value) {
      _initialEntranceComplete = true;
      _entranceProgress.value = 1.0;
    }
}


  @override
  void dispose() {
    staticChooserPage.removeListener(_staticChooserPageChanged);
    _animationController?..removeListener(_updatePaintPhase)..dispose();
    _initialEntranceController?..removeListener(_updateEntranceProgress)..removeStatusListener(_entranceStatusChanged)..dispose();
    _paintPhase.dispose();
    _entranceProgress.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }


  void _staticChooserPageChanged() {
    if (!mounted) return;
    if (staticChooserPage.value) {
      _idleTimer?.cancel();
      _animationController?.stop(canceled: false);
      _initialEntranceController?.stop(canceled: false);
      setState(() { _initialEntranceComplete = true; });
      _entranceProgress.value = 1.0;
      _paintPhase.value = 0.0;
    } else {
      _idleTimer?.cancel();
      setState(() {
        _initialEntranceStarted = true;
        _initialEntranceComplete = false;
      });
      _entranceProgress.value = 0.0;
      _lastEntranceStep = -1;
      _initialEntranceController?.forward(from: 0.0);
      _animationController?.repeat();
    }
  }


  void _updatePaintPhase() { // optimise by only animating fixed number of steps, rather than every frame
    final step = (_animationController!.value * _idleAnimationSteps).floor();
    if (step == _lastPaintStep) return;
    _lastPaintStep = step;
    _paintPhase.value = step / _idleAnimationSteps;
  }


  void _updateEntranceProgress() {
    final step = (_initialEntranceController!.value * _entranceAnimationSteps).floor();
    if (step == _lastEntranceStep) return;
    _lastEntranceStep = step;
    _entranceProgress.value = step / _entranceAnimationSteps;
  }


  void _entranceStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() { _initialEntranceComplete = true; });
    }
  }


  void _pauseAnimationOnPointerDown(PointerDownEvent event) {
    _animationController?.stop(canceled: false);
    if (!staticChooserPage.value) _restartAnimationTimer();
  }


  void _restartAnimationTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: _restartIdleAnimationPeriod), () 
      {
        if (!mounted) return;
        setState(() { _chosenHotspotID = null; });
        _animationController?.repeat();
      },
    );
  }


  void _selectHotspot(int index) {
    _idleTimer?.cancel();
    setState(() { _chosenHotspotID = index; });
    _animationController?.stop(canceled: false);
    hotspots[index].theTap();
  }


  Future<void> _createHotspots(
    double maxWidth,
    double maxHeight,
    double devicePixelRatio,
  ) async {

    hotspots = [
      Hotspot(
        label: 'Food &\nDrink',
        labelLeftOffset: -0.1,
        labelRightOffset: 0,
        labelTopOffset: 0,
        left: -0.03,
        top: 0.01,
        scale: 1,
        assetPath: 'assets/chooserPage/foodDrink.png',
        theTap: () => widget.onOpenListings('all', 'food'),
      ),
      Hotspot(
        label: 'Music',
        labelLeftOffset: -0.04,
        labelRightOffset: 0,
        labelTopOffset: 0.03,
        left: 0.66,
        top: -0.005,
        scale: 1,
        assetPath: 'assets/chooserPage/music.png',
        theTap: () => widget.onOpenTimetable(false, true),
      ),
      Hotspot(
        label: 'Children’s',
        labelLeftOffset: 0.01,
        labelRightOffset: 0,
        labelTopOffset: 0.033,
        left: 0.35,
        top: 0.18,
        scale: 1.05,
        assetPath: 'assets/chooserPage/childrens.png',
        theTap: () => widget.onOpenListings('all', 'performanceChildrens'),
      ),
      Hotspot(
        label: 'Shopping\n& Stalls',
        labelLeftOffset: 0.02,
        labelRightOffset: 0.06,
        labelTopOffset: 0.04,
        left: 0.65,
        top: 0.28,
        scale: 1,
        assetPath: 'assets/chooserPage/shopping.png',
        theTap: () => widget.onOpenListings('all', 'shopping'),
      ),
      Hotspot(
        label: 'Charity,\nCommunity\n& Info',
        labelLeftOffset: 0,
        labelRightOffset: 0,
        labelTopOffset: 0.07,
        left: 0,
        top: 0.29,
        scale: 1,
        assetPath: 'assets/chooserPage/charityCommunityInfo.png',
        theTap: () => widget.onOpenListings('all', 'charityCommunityInfo'),
      ),
      Hotspot(
        label: 'Visit &\nExperience',
        labelLeftOffset: 0.13,
        labelRightOffset: 0,
        labelTopOffset: 0.02,
        left: 0.19,
        top: 0.56,
        scale: 1,
        assetPath: 'assets/chooserPage/visitExperience.png',
        theTap: () => widget.onOpenListings('all', 'visitExperience'),
      ),
      Hotspot(
        label: 'Services',
        labelLeftOffset: 0,
        labelRightOffset: 0,
        labelTopOffset: 0.1,
        left: 0,
        top: 0.69,
        scale: 1,
        assetPath: 'assets/chooserPage/services.png',
        theTap: () => widget.onOpenListings('all', 'service'),
      ),
      Hotspot(
        label: 'Nearby',
        labelLeftOffset: 0.02,
        labelRightOffset: 0,
        labelTopOffset: 0.08,
        left: 0.61,
        top: 0.70,
        scale: 0.9,
        assetPath: 'assets/chooserPage/nearby.png',
        theTap: () => widget.onOpenMap(10),
      ),
    ];

    final screenScaleWidth = maxWidth / 402; // versus reference device
    final screenScaleHeight = maxHeight / 663; // versus reference device

    for (final hotspot in hotspots) {
      final sourceImage = await _resolveImage(AssetImage(hotspot.assetPath));
      if (!mounted) return;
      final width = sourceImage.width * hotspot.scale * screenScaleWidth;
      final height = sourceImage.height * hotspot.scale * screenScaleHeight;
      hotspot.size = Size(width, height);
      hotspot.left *= maxWidth;
      hotspot.top *= maxHeight;
      hotspot.labelLeftOffset *= maxWidth;
      hotspot.labelRightOffset *= maxWidth;
      hotspot.labelTopOffset *= maxHeight;
      final targetWidth = max(1, (width * devicePixelRatio).ceil() + 2);
      hotspot.imageProvider = ResizeImage(AssetImage(hotspot.assetPath), width: targetWidth);
    }

    if (!mounted || staticChooserPage.value) return;
    await Future.wait([
      ...hotspots.map((hotspot) => precacheImage(hotspot.imageProvider!, context)),
      precacheImage(const AssetImage('assets/chooserPage/chooserPage_background.jpg'), context),
      precacheImage(const AssetImage('assets/chooserPage/MRWF_logo_transparent.png'), context),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || staticChooserPage.value) return;
      if (!_initialEntranceStarted) {
        _initialEntranceStarted = true;
        _initialEntranceController?.forward(from: 0.0);
        _animationController?.repeat();
      }
    });

  }


  Future<ui.Image> _resolveImage(
    ImageProvider provider,
  ) {

    final completer = Completer<ui.Image>();
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(info.image);
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(
            error,
            stackTrace,
          );
        }
      },
    );
    stream.addListener(listener);
    return completer.future.whenComplete(() => stream.removeListener(listener));

  }


  @override
  Widget build(BuildContext context) {

    final colourScheme = Theme.of(context).colorScheme;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    return ValueListenableBuilder<bool>(
      valueListenable: staticChooserPage,
      builder: (context, name, child) {
        return Listener(
          onPointerDown: (staticChooserPage.value) ? null : _pauseAnimationOnPointerDown,
          behavior: HitTestBehavior.translucent,
          child: FairScaffold(
            appBarTitle: 'Welcome to the 2026 Fair! ', // deliberate space
            currentTab: 0,
            onTabSelected: widget.onTabSelected,
            appBarActions: [
              IconButton(icon: const Icon(Icons.warning, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportantInfoPage()));
                },
              ),
              IconButton(icon: const ImageIcon(AssetImage('assets/icons/iconTransparent.png')),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
                },
              ),
            ],
            body: RepaintBoundary(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _hotspotsFuture ??= _createHotspots(constraints.maxWidth, constraints.maxHeight, devicePixelRatio);
                  return FutureBuilder<void>(
                    future: _hotspotsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                      return _ChooserContent(
                        hotspots: hotspots,
                        paintPhase: _paintPhase,
                        staticChooserPage: staticChooserPage.value,
                        entranceProgress: _entranceProgress,
                        initialEntranceComplete: _initialEntranceComplete,
                        chosenHotspotID: _chosenHotspotID,
                        colourScheme: colourScheme,
                        onHotspotTap: _selectHotspot,
                        maxWidth: constraints.maxWidth,
                      );
                    },
                  );
                },
              ),
            ),
          )
        );
      },
    );

  }

}


class _ChooserContent extends StatelessWidget {

  const _ChooserContent({
    required this.hotspots,
    required this.paintPhase,
    required this.staticChooserPage,
    required this.entranceProgress,
    required this.initialEntranceComplete,
    required this.chosenHotspotID,
    required this.colourScheme,
    required this.onHotspotTap,
    required this.maxWidth,
  });

  final List<Hotspot> hotspots;
  final ValueListenable<double> paintPhase;
  final bool staticChooserPage;
  final ValueListenable<double> entranceProgress;
  final bool initialEntranceComplete;
  final int? chosenHotspotID;
  final ColorScheme colourScheme;
  final void Function(int index) onHotspotTap;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {

    final visibleCount = min(3, hotspots.length);

    return Stack(fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: _ChooserBackground()),
        for (int index = 0; index < hotspots.length; index++)
          _AnimatedHotspot(
            hotspot: hotspots[index],
            index: index,
            visibleCount: visibleCount,
            paintPhase: paintPhase,
            entranceProgress: entranceProgress,
            initialEntranceComplete: initialEntranceComplete,
            staticChooserPage: staticChooserPage,
            isSelected: chosenHotspotID == index,
            colourScheme: colourScheme,
            onTap: () => onHotspotTap(index),
          ),
        Positioned(top: 20, left: 0, right: 0,
          child: Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTheFairPage()));
              },
              child: const RepaintBoundary(child: _ChooserLogo()),
            ),
          ),
        ),
      ],
    );

  }

}


class _ChooserBackground extends StatelessWidget {

  const _ChooserBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/chooserPage/chooserPage_background.jpg', fit: BoxFit.fill),
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.white.withAlpha(150)),
          ),
        ),
      ],
    );
  }

}


class _ChooserLogo extends StatelessWidget {

  const _ChooserLogo();

  @override
  Widget build(BuildContext context) {
    return SimpleShadow(
      opacity: 1,
      color: Colors.white,
      sigma: 6,
      offset: const Offset(3, 3),
      child: Image.asset(
        'assets/chooserPage/MRWF_logo_transparent.png',
        fit: BoxFit.contain,
        width: MediaQuery.sizeOf(context).width * 0.5,
      ),
    );
  }

}


class _AnimatedHotspot extends StatelessWidget {

  const _AnimatedHotspot({
    required this.hotspot,
    required this.index,
    required this.visibleCount,
    required this.paintPhase,
    required this.entranceProgress,
    required this.initialEntranceComplete,
    required this.staticChooserPage,
    required this.isSelected,
    required this.colourScheme,
    required this.onTap,
  });

  final Hotspot hotspot;
  final int index;
  final int visibleCount;
  final ValueListenable<double> paintPhase;
  final ValueListenable<double> entranceProgress;
  final bool initialEntranceComplete;
  final bool staticChooserPage;
  final bool isSelected;
  final ColorScheme colourScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: hotspot.left,
      top: hotspot.top,
      width: hotspot.size!.width,
      height: hotspot.size!.height,
      child: _HotspotLayers(
        hotspot: hotspot,
        index: index,
        visibleCount: visibleCount,
        paintPhase: paintPhase,
        entranceProgress: entranceProgress,
        initialEntranceComplete: initialEntranceComplete,
        staticChooserPage: staticChooserPage,
        isSelected: isSelected,
        colourScheme: colourScheme,
        onTap: onTap,
      ),
    );
  }

}


class _HotspotLayers extends StatelessWidget {

  const _HotspotLayers({
    required this.hotspot,
    required this.index,
    required this.visibleCount,
    required this.paintPhase,
    required this.entranceProgress,
    required this.initialEntranceComplete,
    required this.staticChooserPage,
    required this.isSelected,
    required this.colourScheme,
    required this.onTap,
  });

  final Hotspot hotspot;
  final int index;
  final int visibleCount;
  final ValueListenable<double> paintPhase;
  final ValueListenable<double> entranceProgress;
  final bool initialEntranceComplete;
  final bool staticChooserPage;
  final bool isSelected;
  final ColorScheme colourScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final animation = Listenable.merge([paintPhase, entranceProgress]);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        if (staticChooserPage) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _CachedNormalImage(hotspot: hotspot),
                _CachedLabel(hotspot: hotspot, colourScheme: colourScheme),
              ],
            ),
          );
        }
        final introProgress = entranceProgress.value;
        final idleProgress = paintPhase.value;
        final introOpacity = isSelected
            ? 1.0
            : hotspotEntranceOpacityForIndex(
                index,
                introProgress,
                totalHotspots: 8,
              );
        final idleOpacity = isSelected
            ? 1.0
            : hotspotLabelOpacityForPhase(
                index,
                idleProgress,
                visibleCount: visibleCount,
              );
        final imageOpacity = initialEntranceComplete ? 1.0 : introOpacity;
        final glowOpacity = initialEntranceComplete ? idleOpacity : 0.0;
        final labelOpacity = initialEntranceComplete ? idleOpacity : 0.0;
        final shadowedOpacity = imageOpacity * glowOpacity;
        final normalOpacity = imageOpacity * (1.0 - glowOpacity); // so they combine to 100%
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _AnimatedOpacityLayer(opacity: shadowedOpacity, child: _CachedShadowedImage(hotspot: hotspot)),
              _AnimatedOpacityLayer(opacity: normalOpacity, child: _CachedNormalImage(hotspot: hotspot)),
              _AnimatedOpacityLayer(opacity: labelOpacity, child: _CachedLabel(hotspot: hotspot, colourScheme: colourScheme)),
            ],
          ),
        );
      },
    );
  }

}


class _AnimatedOpacityLayer extends StatelessWidget {

  const _AnimatedOpacityLayer({
    required this.opacity,
    required this.child,
  });

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.0) return const SizedBox.shrink(); // for efficiency
    if (opacity >= 1.0) return child; // for efficiency
    return Opacity(opacity: opacity, child: child);
  }

}


class _CachedShadowedImage extends StatelessWidget {

  const _CachedShadowedImage({
    required this.hotspot,
  });

  final Hotspot hotspot;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SimpleShadow(
        opacity: 1.0,
        color: Colors.black,
        sigma: 10.0,
        offset: const Offset(6, 6),
        child: Image(
          image: hotspot.imageProvider!,
          width: hotspot.size!.width,
          height: hotspot.size!.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

}


class _CachedNormalImage extends StatelessWidget {

  const _CachedNormalImage({
    required this.hotspot,
  });

  final Hotspot hotspot;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image(
        image: hotspot.imageProvider!,
        width: hotspot.size!.width,
        height: hotspot.size!.height,
        fit: BoxFit.contain,
      ),
    );
  }

}


class _CachedLabel extends StatelessWidget {
  
  const _CachedLabel({
    required this.hotspot,
    required this.colourScheme,
  });

  final Hotspot hotspot;
  final ColorScheme colourScheme;

  @override
  Widget build(BuildContext context) {
    final maxFontSize = (MediaQuery.of(context).size.width > 400) ? 27.0 : 22.0;
    return Stack(children: [ // single-item stack since it's a child of Opacity()
      Positioned(
        left: hotspot.labelLeftOffset,
        width: hotspot.size!.width - hotspot.labelLeftOffset - hotspot.labelRightOffset,
        top: hotspot.labelTopOffset,
        height: hotspot.size!.height - hotspot.labelTopOffset,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          width: hotspot.size!.width - hotspot.labelLeftOffset - hotspot.labelRightOffset,
          child: RepaintBoundary(
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(
              hotspot.label,
              textAlign: TextAlign.center,
              softWrap: false,
              style: TextStyle(fontSize: maxFontSize, fontWeight: FontWeight.bold, color: Colors.white, height: 0.9,
                shadows: [
                  const Shadow(blurRadius: 4, color: Colors.black),
                  Shadow(blurRadius: 16, color: colourScheme.primary),
                ],
              ),
            )),
          ),
        ),
      ),
    ]);
  }

}


double hotspotEntranceOpacityForIndex(
  int index,
  double progress, {
  required int totalHotspots,
}) {

  if (totalHotspots <= 0) return 1.0;
  if (progress <= 0.0) return 0.0;
  final revealStart = 0.1 + ((index / totalHotspots) * 0.8);
  final revealEnd = revealStart + 0.12;
  if (progress < revealStart) return 0.0;
  if (progress >= revealEnd) return 1.0;
  final localProgress = (progress - revealStart) / (revealEnd - revealStart);
  return localProgress.clamp(0.0, 1.0);

}


double hotspotLabelOpacityForPhase(
  int index,
  double progress, {
  required int visibleCount,
}) {

  if (visibleCount <= 1) return 1.0;
  final slot = index % visibleCount;
  final normalized = (progress + (slot / visibleCount)) % 1.0;
  final wave = 0.5 + (0.5 * cos(2 * pi * normalized));
  return wave.clamp(0.0, 1.0);

}


class Hotspot {
  Hotspot({
    required this.label,
    required this.assetPath,
    required this.left,
    required this.top,
    required this.scale,
    required this.theTap,
    required this.labelTopOffset,
    required this.labelLeftOffset,
    required this.labelRightOffset,
  });

  final String label;
  final String assetPath;
  final double scale;
  final VoidCallback theTap;
  // below are all (re)calculated as images are loaded
  double left;
  double top;
  double labelTopOffset;
  double labelLeftOffset;
  double labelRightOffset;
  Size? size;
  ImageProvider? imageProvider;
}
