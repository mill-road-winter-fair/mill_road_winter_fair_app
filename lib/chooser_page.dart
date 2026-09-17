import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/about_the_fair.dart';
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

class _ChooserPageState extends State<ChooserPage> {
  // Rebase after scrolling to keep an unlimited number of cycles in both directions.
  static const _origin = 8000;
  final _controller =
      PageController(initialPage: _origin, viewportFraction: .82);
  int _selected = 0;

  List<_Choice> get _choices => [
        _Choice('Food & Drink', 'Find something delicious', 'foodDrink',
            () => widget.onOpenListings('all', 'food')),
        _Choice('Music', 'Discover the soundtrack to your day', 'music',
            () => widget.onOpenTimetable(false, true)),
        _Choice(
            'Children’s',
            'Little adventures for little visitors',
            'childrens',
            () => widget.onOpenListings('all', 'performanceChildrens')),
        _Choice('Shopping & Stalls', 'Browse, discover and shop local',
            'shopping', () => widget.onOpenListings('all', 'shopping')),
        _Choice(
            'Charity, Community & Info',
            'Meet the people who make the Fair',
            'charityCommunityInfo',
            () => widget.onOpenListings('all', 'charityCommunityInfo')),
        _Choice(
            'Visit & Experience',
            'Explore something a little different',
            'visitExperience',
            () => widget.onOpenListings('all', 'visitExperience')),
        _Choice('Services', 'Useful stops along the way', 'services',
            () => widget.onOpenListings('all', 'service')),
        _Choice('Nearby', 'See what’s around you', 'nearby',
            () => widget.onOpenMap(10)),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final target = (_controller.page ?? _origin.toDouble()).round() + delta;
    if (MediaQuery.disableAnimationsOf(context) || staticChooserPage.value) {
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
    final theme = Theme.of(context);
    final colours = theme.colorScheme;
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
        child: LayoutBuilder(builder: (context, constraints) {
          final contentWidth = math.min(680.0, constraints.maxWidth);
          final compact = constraints.maxHeight < 650;
          final shortScreen = constraints.maxHeight < 560;
          final logoHeight = shortScreen
              ? 32.0
              : compact
                  ? 64.0
                  : 100.0;
          final outerSpacing = shortScreen
              ? 4.0
              : compact
                  ? 8.0
                  : 20.0;
          final captionPadding = shortScreen ? 12.0 : 20.0;
          final titleStyle = (shortScreen
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleLarge)
              ?.copyWith(fontWeight: FontWeight.bold);
          final textWidth = math.max(
              1.0,
              contentWidth * .82 -
                  12 -
                  captionPadding * 2 -
                  (shortScreen ? 0 : 36));
          double textHeight(String text, TextStyle? style, {double? width}) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: width ?? textWidth);
            final height = painter.height;
            painter.dispose();
            return height;
          }

          final captionHeight = choices
              .map((choice) =>
                  textHeight(choice.title, titleStyle) +
                  textHeight(choice.description, theme.textTheme.bodyMedium) +
                  captionPadding * 2 +
                  6)
              .reduce(math.max);
          // Reserve room for the header and controls before sizing the artwork.
          // Artwork yields space to captions. Only exceptionally large text
          // needs the outer scroll view; ordinary small phones fit in one view.
          final headingHeight = textHeight(
              'Find your Fair',
              theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              width: math.max(1.0, contentWidth - 48));
          final hintHeight = textHeight(
              'Swipe to explore. Tap to discover.', theme.textTheme.bodyMedium,
              width: math.max(1.0, contentWidth - 48));
          final controlsHeight =
              math.max(48.0, textHeight('8 / 8', theme.textTheme.labelLarge));
          final chromeHeight = outerSpacing * 2 +
              logoHeight +
              (shortScreen ? 28 : 60) +
              (shortScreen ? 0 : headingHeight + hintHeight) +
              controlsHeight;
          final cardHeight = (constraints.maxHeight - chromeHeight).clamp(
              captionHeight + (shortScreen ? 56 : 96), captionHeight + 468);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: outerSpacing),
                      Semantics(
                        label: 'Mill Road Winter Fair. About the Fair',
                        button: true,
                        child: InkWell(
                          onTap: _about,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/chooserPage/MRWF_logo_transparent.png',
                              width: math.min(220.0, contentWidth * .6),
                              height: logoHeight,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ),
                      if (!shortScreen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                          child: Text('Find your Fair',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        ),
                      if (!shortScreen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Text('Swipe to explore. Tap to discover.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: colours.onSurfaceVariant),
                              textAlign: TextAlign.center),
                        ),
                      SizedBox(
                        height: cardHeight,
                        child: NotificationListener<ScrollEndNotification>(
                          onNotification: _rebase,
                          child: PageView.builder(
                            key: const ValueKey('chooser-carousel'),
                            controller: _controller,
                            onPageChanged: (page) => setState(
                                () => _selected = page % choices.length),
                            itemBuilder: (context, page) {
                              final index = page % choices.length;
                              return AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  final position = _controller.hasClients &&
                                          _controller
                                              .position.hasContentDimensions
                                      ? _controller.page ?? _origin.toDouble()
                                      : _origin.toDouble();
                                  final distance =
                                      (position - page).abs().clamp(0.0, 1.0);
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6 +
                                            distance * (shortScreen ? 6 : 18)),
                                    child: child,
                                  );
                                },
                                child: _ChoiceCard(
                                  choice: choices[index],
                                  selected: index == _selected,
                                  index: index,
                                  total: choices.length,
                                  titleStyle: titleStyle,
                                  captionPadding: captionPadding,
                                  showArrow: !shortScreen,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 12, 24, outerSpacing),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Previous category',
                              onPressed: () => _move(-1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            const SizedBox(width: 20),
                            Semantics(
                              liveRegion: true,
                              label:
                                  '${choices[_selected].title}, category ${_selected + 1} of ${choices.length}',
                              child: ExcludeSemantics(
                                child: Text(
                                    '${_selected + 1} / ${choices.length}',
                                    style: theme.textTheme.labelLarge),
                              ),
                            ),
                            const SizedBox(width: 20),
                            IconButton.filledTonal(
                              tooltip: 'Next category',
                              onPressed: () => _move(1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Choice {
  const _Choice(this.title, this.description, this.asset, this.onTap);
  final String title;
  final String description;
  final String asset;
  final VoidCallback onTap;
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard(
      {required this.choice,
      required this.selected,
      required this.index,
      required this.total,
      required this.titleStyle,
      required this.captionPadding,
      required this.showArrow});
  final _Choice choice;
  final bool selected;
  final int index;
  final int total;
  final TextStyle? titleStyle;
  final double captionPadding;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colours = theme.colorScheme;
    return Semantics(
      button: true,
      label: '${choice.title}, ${index + 1} of $total. ${choice.description}',
      onTap: choice.onTap,
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: selected ? 2 : 0,
        color: colours.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
              color: selected
                  ? colours.primary.withAlpha(100)
                  : colours.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('choice-${choice.asset}'),
          onTap: () {
            HapticFeedback.selectionClick();
            choice.onTap();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(showArrow ? 24 : 12),
                  child: Ink(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            'assets/chooserPage/${choice.asset}.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(captionPadding),
                decoration: BoxDecoration(
                  color: colours.surface.withAlpha(245),
                  border:
                      Border(top: BorderSide(color: colours.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(choice.title, style: titleStyle),
                          const SizedBox(height: 6),
                          Text(choice.description,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: colours.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    if (showArrow) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.arrow_forward, color: colours.primary),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
