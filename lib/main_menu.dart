import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({
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
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  // Rebase after scrolling to keep an unlimited number of cycles in both directions.
  static const _origin = 8000;
  final _controller =
      PageController(initialPage: _origin, viewportFraction: .56);
  int _selected = 0;

  List<_FairChoice> get _choices => [
        _FairChoice('Food & Drink', 'Find something delicious', 'foodDrink',
            () => widget.onOpenListings('all', 'food')),
        _FairChoice('Music', 'Discover the soundtrack to your day', 'music',
            () => widget.onOpenTimetable(false, true)),
        _FairChoice(
            'Children’s',
            'Little adventures for little visitors',
            'childrens',
            () => widget.onOpenListings('all', 'performanceChildrens')),
        _FairChoice('Shopping & Stalls', 'Browse, discover and shop local',
            'shopping', () => widget.onOpenListings('all', 'shopping')),
        _FairChoice(
            'Charity, Community & Info',
            'Meet the people who make the Fair',
            'charityCommunityInfo',
            () => widget.onOpenListings('all', 'charityCommunityInfo')),
        _FairChoice(
            'Visit & Experience',
            'Explore something a little different',
            'visitExperience',
            () => widget.onOpenListings('all', 'visitExperience')),
        _FairChoice('Services', 'Useful stops along the way', 'services',
            () => widget.onOpenListings('all', 'service')),
        _FairChoice('Nearby', 'See what’s around you', 'nearby',
            () => widget.onOpenMap(10)),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final target = (_controller.page ?? _origin.toDouble()).round() + delta;
    if (MediaQuery.disableAnimationsOf(context) || staticMainMenuPage.value) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic);
    }
  }

  bool _rebase(ScrollEndNotification notification) {
    if (notification.depth == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !_controller.hasClients ||
            _controller.position.isScrollingNotifier.value) {
          return;
        }
        final page = _controller.page!;
        final target = _origin + _selected;
        if ((page - page.round()).abs() < .001 && page.round() != target) {
          _controller.jumpToPage(target);
        }
      });
    }
    return false;
  }

  void _about() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const AboutTheFairPage()));

  @override
  Widget build(BuildContext context) {
    final choices = _choices;
    return FairScaffold(
      appBarTitle: 'Welcome to the 2026 Fair! ',
      currentTab: 0,
      onTabSelected: widget.onTabSelected,
      appBarActions: [
        IconButton(
          tooltip: 'Important information',
          icon: const Icon(Icons.warning, size: 20),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ImportantInfoPage())),
        ),
        IconButton(
          tooltip: 'About the Fair',
          icon: const ImageIcon(AssetImage('assets/icons/iconTransparent.png')),
          onPressed: _about,
        ),
      ],
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: staticMainMenuPage,
          builder: (context, staticMode, _) => Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                  child: _DiffuseArtwork(
                asset: choices[_selected].asset,
                reduceMotion:
                    staticMode || MediaQuery.disableAnimationsOf(context),
              )),
              _FairCarousel(
                controller: _controller,
                choices: choices,
                selected: _selected,
                reduceMotion:
                    staticMode || MediaQuery.disableAnimationsOf(context),
                onSelected: (page) =>
                    setState(() => _selected = page % choices.length),
                onScrollEnd: _rebase,
                onMove: _move,
                onAbout: _about,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FairChoice {
  const _FairChoice(this.title, this.description, this.asset, this.onTap);
  final String title;
  final String description;
  final String asset;
  final VoidCallback onTap;
}

/// A scroll-driven arc inspired by Wonderous's artefact gallery. Captions
/// remain outside the moving artwork so they never shrink or get clipped.
class _FairCarousel extends StatelessWidget {
  const _FairCarousel(
      {required this.controller,
      required this.choices,
      required this.selected,
      required this.reduceMotion,
      required this.onSelected,
      required this.onScrollEnd,
      required this.onMove,
      required this.onAbout});
  final PageController controller;
  final List<_FairChoice> choices;
  final int selected;
  final bool reduceMotion;
  final ValueChanged<int> onSelected;
  final bool Function(ScrollEndNotification) onScrollEnd;
  final ValueChanged<int> onMove;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final landscape = constraints.maxWidth >= 600 &&
          constraints.maxWidth > constraints.maxHeight * 1.25;
      final width = math.min(landscape ? 1000.0 : 680.0, constraints.maxWidth);
      final compact = constraints.maxHeight < 600;
      final logoHeight = compact ? 32.0 : 72.0;
      final titleStyle = (compact
              ? theme.textTheme.titleMedium
              : theme.textTheme.headlineSmall)
          ?.copyWith(fontWeight: FontWeight.bold);
      final captionWidth = landscape ? width * .42 : width;
      double measure(String text, TextStyle? style) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: math.max(1, captionWidth - (compact ? 64 : 96)));
        final height = painter.height;
        painter.dispose();
        return height;
      }

      final captionHeight = choices
          .map((choice) =>
              measure(choice.title, titleStyle) +
              measure(choice.description, theme.textTheme.bodyMedium) +
              38)
          .reduce(math.max);
      final availableHeight = constraints.maxHeight - logoHeight - 16;
      final stageHeight = landscape
          ? math.max(captionHeight, availableHeight).clamp(96.0, 600.0)
          : (availableHeight - captionHeight).clamp(72.0, 520.0);
      final stage = SizedBox(height: stageHeight, child: _buildOrbit(context));
      final details = Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          key: const ValueKey('category-caption-box'),
          height: captionHeight,
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.center,
              children: [
                for (final child in previous)
                  ExcludeSemantics(child: IgnorePointer(child: child)),
                if (current != null) current,
              ],
            ),
            child: Padding(
              key: ValueKey(selected),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('selected-category'),
                    onTap: choices[selected].onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(
                            child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(choices[selected].title, style: titleStyle),
                            const SizedBox(height: 6),
                            Text(choices[selected].description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        )),
                        if (!compact) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward,
                              color: theme.colorScheme.primary),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
              child: SizedBox(
            width: width,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Semantics(
                  label: 'Mill Road Winter Fair. About the Fair',
                  button: true,
                  child: InkWell(
                      onTap: onAbout,
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                          'assets/mainMenuPage/MRWF_logo_transparent.png',
                          height: logoHeight,
                          width: math.min(240, width * .6),
                          fit: BoxFit.contain,
                          excludeFromSemantics: true)),
                ),
              ),
              Flex(
                  direction: landscape ? Axis.horizontal : Axis.vertical,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        width: landscape ? width * .58 : width, child: stage),
                    SizedBox(width: captionWidth, child: details),
                  ]),
            ]),
          )),
        ),
      );
    });
  }

  Widget _buildOrbit(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight;
      // Align the equator with the stage's lower edge (the portrait caption top).
      final snowflakeSize = height * .95;
      return ClipRect(
          child: Stack(children: [
        Positioned.fill(
            child: IgnorePointer(
                child: CustomPaint(painter: _OrbitBackdrop(colours.primary)))),
        Positioned(
          bottom: -snowflakeSize / 2,
          left: (constraints.maxWidth - snowflakeSize) / 2,
          width: snowflakeSize,
          height: snowflakeSize,
          child: IgnorePointer(
              child: RepaintBoundary(
            child: SvgPicture.asset('assets/mainMenuPage/snowflake.svg',
                key: const ValueKey('carousel-snowflake'),
                excludeFromSemantics: true,
                colorFilter: ColorFilter.mode(
                    colours.primary.withAlpha(65), BlendMode.srcIn)),
          )),
        ),
        NotificationListener<ScrollEndNotification>(
          onNotification: onScrollEnd,
          child: PageView.builder(
            key: const ValueKey('main-menu-carousel'),
            controller: controller,
            onPageChanged: onSelected,
            itemBuilder: (context, page) {
              final choice = choices[page % choices.length];
              return AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final position = controller.hasClients &&
                          controller.position.hasContentDimensions
                      ? controller.page ?? controller.initialPage.toDouble()
                      : controller.initialPage.toDouble();
                  final distance = (position - page).abs().clamp(0.0, 2.0);
                  // The focal portrait rises; neighbours collapse and descend.
                  final progress =
                      Curves.easeInOut.transform(distance.clamp(0.0, 1.0));
                  final collapse = reduceMotion ? 0.0 : progress;
                  final itemWidth =
                      math.min(constraints.maxWidth * .56 - 24, height * .54);
                  final portraitHeight =
                      math.min(height * .72, itemWidth * 1.5);
                  final itemHeight = portraitHeight * (1 - collapse / 3);
                  final top = height * (.03 + .32 * collapse);
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: top),
                      child: SizedBox(
                        width: itemWidth,
                        height: itemHeight,
                        child: Semantics(
                          button: true,
                          label: choice.title,
                          hint: page % choices.length == selected
                              ? 'Open category'
                              : 'Bring category to centre',
                          child: Material(
                            color: Color.alphaBlend(
                                colours.primary.withAlpha(10), colours.surface),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: BorderSide(
                                    color: colours.primary.withAlpha(
                                        (210 - 110 * progress).round()),
                                    width: 1.5)),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('choice-${choice.asset}'),
                              onTap: () {
                                if (page % choices.length == selected) {
                                  choice.onTap();
                                } else {
                                  onMove(page - position.round());
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.all(
                                    math.min(24, itemWidth * .12)),
                                child: Ink(
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage(
                                                'assets/mainMenuPage/${choice.asset}.png'),
                                            fit: BoxFit.contain))),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]));
    });
  }
}

/// Filter only the artwork, keeping foreground text and controls sharp.
class _DiffuseArtwork extends StatelessWidget {
  const _DiffuseArtwork({required this.asset, required this.reduceMotion});
  final String asset;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return IgnorePointer(
        child: ExcludeSemantics(
            child: ClipRect(
      child: ColoredBox(
        color: colours.surface,
        child: AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 650),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (current != null) current]),
          child: RepaintBoundary(
            key: ValueKey('diffuse-$asset'),
            child: Opacity(
              opacity: colours.brightness == Brightness.dark ? .16 : .22,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: Transform.scale(
                    scale: 1.6,
                    child: Image.asset('assets/mainMenuPage/$asset.png',
                        fit: BoxFit.cover,
                        cacheWidth: 720,
                        excludeFromSemantics: true)),
              ),
            ),
          ),
        ),
      ),
    )));
  }
}

class _OrbitBackdrop extends CustomPainter {
  const _OrbitBackdrop(this.colour);
  final Color colour;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(-size.width * .3, size.height * .58,
        size.width * 1.6, size.height * 1.4);
    canvas.drawOval(rect, Paint()..color = colour.withAlpha(9));
    canvas.drawOval(
        rect,
        Paint()
          ..color = colour.withAlpha(30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_OrbitBackdrop oldDelegate) =>
      oldDelegate.colour != colour;
}
