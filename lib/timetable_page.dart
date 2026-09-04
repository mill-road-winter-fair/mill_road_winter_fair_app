import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

class TimetablePage extends StatefulWidget {
  final List<Map<String, dynamic>> theEvents;
  final ValueChanged<int> onTabSelected;
  final Function(bool, bool?) onFilterChange;
  final String? listingToShow;
  final bool onlyNowOrSoon;
  final bool? filteredMusicOrNot;
  const TimetablePage({
    required this.theEvents,
    required this.onTabSelected,
    required this.onFilterChange,
    this.listingToShow,
    required this.onlyNowOrSoon,
    this.filteredMusicOrNot,
    super.key,
  });
  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _nowLineTimer;
  final nowLineKey = GlobalKey();
  late double _dayPixelsPerMinute; // scale for the current day view, whatever its orientation
  late double pixelsPerMinuteL, pixelsPerMinuteP; // orientation-specific scales
  Orientation? _deviceOrientationSaved; // to track if this has changed
  bool scaling = false; // tracks whether user is re-scaling the view
  bool? _onlyNowOrSoonSaved; // to track if this has changed
  bool? _filteredMusicOrNotSaved; // to track if this has changed
  String _searchQuery = '';
  bool _isSearching = false; // true when the search bar is open (with/without text)
  static const leftColumnWidth = 44.0; // how much space to leave for the time labels
  late DateTime timelineMinStart; // the start of the timeline after filtering
  late DateTime timelineMaxEnd; // the end of the timeline after filtering
  late int spanMinutes; // difference between the above
  late double pxPerMin; // pixels per minute for time axis scaling
  late double totalWidth; // total pixel width of the columns content
  late double columnWidth; // calculated width of columns, depending on quantity
  late Map<String, List<PositionedEvent>> thePreparedEvents; // read from the listings
  late Map<String, List<PositionedEvent>> theFilteredEvents; // filtered from the above based on onlyNowOrSoon
  bool loading = true; // so we don't try to build before we're ready

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    thePreparedEvents = prepareEvents(widget.theEvents);
    loadScales();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _nowLineTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  // so app knows if the device has been rotated, and can restore any previous scroll/sizing
  void didChangeDependencies() {
    debugPrint('_TimetablePageState didChangeDependencies called');
    final Orientation currentOrientation = MediaQuery.orientationOf(context);
    if (_deviceOrientationSaved !=null && currentOrientation != _deviceOrientationSaved) { // i.e. device has been rotated (or this is the first check)
      if (_deviceOrientationSaved != null) debugPrint('_TimetablePageState didChangeDependencies: changed orientation, _deviceOrientation=$_deviceOrientationSaved currentOrientation=$currentOrientation');
      removeMiniPopup();
      safeRemoveRoute(context, listingDetailsDialogRoute);
      if (currentOrientation == Orientation.landscape) {
        _dayPixelsPerMinute = pixelsPerMinuteL; // the local version which may have changed from that in schedule
      } else {
        _dayPixelsPerMinute = pixelsPerMinuteP; // the local version which may have changed from that in schedule
      }
      _deviceOrientationSaved = MediaQuery.orientationOf(context);
    }
    super.didChangeDependencies();
  }


  void loadScales() async {
    debugPrint('_TimetablePageState loadScales called');
    final prefs = await SharedPreferences.getInstance();
    pixelsPerMinuteL = prefs.getDouble('pixelsPerMinuteL') ?? 0;
    pixelsPerMinuteP = prefs.getDouble('pixelsPerMinuteP') ?? 0;
    setState(() => loading = false); // this should be the last instruction of the last part of async initialisations
  }


  void saveScales() async {
    debugPrint('_TimetablePageState saveScales called');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pixelsPerMinuteP', pixelsPerMinuteP);
    await prefs.setDouble('pixelsPerMinuteL', pixelsPerMinuteL);
  }


  void calculateInitialScalesIfNeeded() async {
    if (pixelsPerMinuteP == 0 || pixelsPerMinuteL == 0) {
      debugPrint('_TimetablePageState calculateInitialScalesIfNeeded estimating initial scale');
      pixelsPerMinuteP = max(0.8, min(1.5, 1000 / max(240, spanMinutes)));
      pixelsPerMinuteL = max(0.8, min(1.5, 600 / max(240, spanMinutes)));
      saveScales();
    }
  }


  void startClockUpdates(VoidCallback tick) {
    final now = DateTime.now();
    final delay = Duration(seconds: (60 / _dayPixelsPerMinute).toInt());
    final initialDelay = delay - Duration(seconds: now.second, milliseconds: now.millisecond);
    _nowLineTimer?.cancel();
    Future.delayed(initialDelay, () {
      tick();
      _nowLineTimer = Timer.periodic(delay, (_) => tick());
    });
    debugPrint('_TimetablePageState startClockUpdates started initially $initialDelay then every $delay for function $tick');
  }


  void updateNowLine() {
    if (mounted) setState(() {});
  }


  DateTime combineDateAndTime(String theTime, DateTime theDate) {
    final parts = theTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final result = DateTime(
      theDate.year,
      theDate.month,
      theDate.day,
      hour,
      minute,
    );
    return result;
  }


  Map<String, List<PositionedEvent>> prepareEvents(List<Map<String, dynamic>> theEvents) {
    Map<String, List<PositionedEvent>> preparedEvents = {};
    for (var ev in theEvents) {
      final startTime = combineDateAndTime(ev['startTime'], fairDate);
      final endTime = combineDateAndTime(ev['endTime'], fairDate);
      if ((
          (ev['performanceMusic'] != null && ev['performanceMusic'] == 'TRUE') 
          || (ev['performanceChildrens'] != null && ev['performanceChildrens'] == 'TRUE') 
          || (ev['performanceDance'] != null && ev['performanceDance'] == 'TRUE')
          || (ev['performanceOther'] != null && ev['performanceOther'] == 'TRUE')
          || (ev['visitExperience'] != null && ev['visitExperience'] == 'TRUE')
        )
        && endTime.difference(startTime).inMinutes < 120 
      ) {
        final eventLocation = ev['location'];
        final thePreparedEvent = PositionedEvent(
          startTime: startTime,
          endTime: endTime,
          location: ev['location'],
          name: ev['title'],
          subtitle: ev['subtitle'],
          id: ev['id'],
          cancelled: (ev['cancelled'] == 'TRUE'),
          emoji: ev['emoji'] ?? '',
          description: ev['description'] ?? '',
          latLng: stringToLatLng(ev['latLng']),
          imageURL: ev['imageURL'] ?? '',
          brickAndMortar: ((ev['brickAndMortar'] ?? '') == 'TRUE'),
          email: ev['email'] ?? '',
          website: ev['website'] ?? '',
          phoneNumber: ev['phoneNumber'] ?? '',
          isMusic: ((ev['performanceMusic'] ?? '') == 'TRUE'),
          lane: 0, // will be computed later
          top: 0, // will be computed later
          height: 0, // will be computed later
          left: 0, // will be computed later
          width: 0, // will be computed later
        );
        if (preparedEvents.keys.contains(eventLocation)) {
          preparedEvents[eventLocation]!.add(thePreparedEvent);
        } else if (eventLocation != null) {
          preparedEvents[eventLocation] = [thePreparedEvent];
        }
      }
    }
    preparedEvents.forEach((loc, events) => events.sort((a, b) => a.startTime.compareTo(b.startTime)));
    return Map.fromEntries(
      preparedEvents.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );  
  }


  Map<String, List<PositionedEvent>> filterEventsAndComputeDefaults(Map<String, List<PositionedEvent>> theEvents, bool onlyNowOrSoon, bool? filteredMusicOrNot, String searchQuery) {
    debugPrint('_TimetablePageState filterEventsAndComputeDefaults called with onlyNowOrSoon=$onlyNowOrSoon filteredMusicOrNot=$filteredMusicOrNot searchQuery=$searchQuery');
    timelineMinStart = DateTime(9999);
    timelineMaxEnd = DateTime(0);
    final now = DateTime.now();
    Map<String, List<PositionedEvent>> theFilteredEvents = {};
    for (final location in theEvents.entries) {
      final theEventsAtThisLocation = location.value;
      for (int i=0; i<theEventsAtThisLocation.length; i++) {
        final ev = theEventsAtThisLocation[i];
        if (!ev.cancelled 
              && (!onlyNowOrSoon 
                || (ev.startTime.isBefore(now) && ev.endTime.difference(now).inMinutes >= -5) 
                || (ev.startTime.isAfter(now) && (ev.startTime.difference(now).inMinutes <= 30)))
              && (searchQuery == '' || ev.name.toString().toLowerCase().contains(_searchQuery))
              && (filteredMusicOrNot == null || (filteredMusicOrNot == true && ev.isMusic) || (filteredMusicOrNot == false && !ev.isMusic))
            ) {
          if (theFilteredEvents.keys.contains(location.key)) {
            theFilteredEvents[location.key]!.add(ev);
          } else {
            theFilteredEvents[location.key] = [ev];
          }
          if (ev.startTime.difference(timelineMinStart).inMinutes < 0) timelineMinStart = ev.startTime;
          if (ev.endTime.difference(timelineMaxEnd).inMinutes > 0) timelineMaxEnd = ev.endTime;
        }
      }
    }
    spanMinutes = timelineMaxEnd.difference(timelineMinStart).inMinutes + 12;
    return theFilteredEvents;
  }


  static List<PositionedEvent> computeLanes(List<PositionedEvent> events, DateTime minStart, double pxPerMin, double columnWidth) {
    // to allow for potentially multiple listings within one column i.e. concurrent events in the same venue
    final lanesEnds = <DateTime>[];
    final List<PositionedEvent> out = [];
    for (var ev in events) {
      int lane = -1;
      for (int i = 0; i < lanesEnds.length; i++) {
        if (!ev.startTime.isBefore(lanesEnds[i])) {
          lane = i;
          break;
        }
      }
      if (lane == -1) {
        lane = lanesEnds.length;
        lanesEnds.add(ev.endTime);
      } else {
        lanesEnds[lane] = ev.endTime;
      }
      final top = ev.startTime.difference(minStart).inMinutes * pxPerMin;
      // the below minimum of 12 does cause overlap of small events when display scaled right down
      // but it's a trade-off between that and overflow exceptions
      final height = max(12.0, ev.endTime.difference(ev.startTime).inMinutes * pxPerMin);
      out.add(PositionedEvent(
        startTime: ev.startTime, 
        endTime: ev.endTime, 
        location: ev.location,
        name: ev.name,
        subtitle: ev.subtitle,
        id: ev.id,
        cancelled: ev.cancelled,
        emoji: ev.emoji,
        description: ev.description,
        latLng: ev.latLng,
        imageURL: ev.imageURL,
        brickAndMortar: ev.brickAndMortar,
        email: ev.email,
        website: ev.website,
        phoneNumber: ev.phoneNumber,
        isMusic: ev.isMusic,
        lane: lane,
        top: top + 2, 
        height: height,
        left: 0, // will be calculated below
        width: 0, // will be calculated below
      ));
    }
    // After lanes assigned, compute widths: each event width = columnWidth * (1 / lanes)
    final laneCount = max(1, lanesEnds.length);
    final laneWidth = columnWidth / laneCount;
    final laneGap = (laneCount > 1) ? 4 : 8;
    for (var pe in out) {
      final overlaps = out.any((o) =>
          o.id != pe.id &&
          o.startTime.isBefore(pe.endTime) &&
          o.endTime.isAfter(pe.startTime));
      if (overlaps) {
        pe.left = pe.lane * laneWidth + laneGap / 2;
        pe.width = max(8, laneWidth - laneGap);
      } else {
        pe.left = laneGap / 2;
        pe.width = columnWidth - laneGap;
      }
    }
    return out;
  }


  Widget eventRect(PositionedEvent pe, ColorScheme colorScheme, bool isLandscape, GlobalKey? possibleKey) {

    return LayoutBuilder(builder: (context, constraints) {

      const double minTitleFontSize = 10.5;
      const double minTimeFontSize = 9.5;
      const double step = 0.5;

      // Snap helper (required by AutoSizeText)
      double snap(double value, double min) {
        final steps = ((value - min) / step).floor();
        return min + steps * step;
      }

      final bool includeDate = (pe.height >= 42 && pe.width >= 80);

      final rawMaxTitleFontSize = min(
        pe.height * 0.3,
        pe.width * 0.3,
      ).clamp(12.0, isLandscape ? 16.5 : 14.5);
      final maxTitleFontSize = max(minTitleFontSize, snap(rawMaxTitleFontSize, minTitleFontSize));
      final maxLines = (pe.height / (minTitleFontSize * 1.1)).floor() - (includeDate ? 1 : 0);

      final rawMaxTimeFontSize = (9.0 + 0.7 * (pe.width / 20)).clamp(8.0, 13.0);
      final maxTimeFontSize = max(minTimeFontSize, snap(rawMaxTimeFontSize, minTimeFontSize));

      return SizedBox(
        width: constraints.maxWidth,
        height: pe.height,
        child: Column(
          key: possibleKey,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: AutoSizeText('${pe.name}\u{00AD}', 
                style: TextStyle(height: 0.95, fontSize: maxTitleFontSize, fontWeight: FontWeight.bold),
                maxLines: maxLines,
                minFontSize: minTitleFontSize,
                maxFontSize: maxTitleFontSize,
                stepGranularity: step,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
            ),
            if (includeDate) SizedBox(height: (pe.height * 0.05).clamp(2, pe.height * 0.25)),
            if (includeDate) Container(
              height: 1.1 * maxTimeFontSize,
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: AutoSizeText(
                formatTimeRange(pe.startTime, pe.endTime),
                style: TextStyle(height: 1.1, fontSize: maxTimeFontSize, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                minFontSize: minTimeFontSize,
                maxFontSize: maxTimeFontSize,
                stepGranularity: step,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    });
  }


  void scrollToKey(GlobalKey theKey, double alignment) async {
    debugPrint('_TimetablePageState scrollToKey called with theKey=$theKey alignment=$alignment');
    final keyContext = theKey.currentContext;
    if (keyContext == null) return;
    final renderObject = keyContext.findRenderObject();
    if (renderObject is! RenderBox) return;
    final viewport = RenderAbstractViewport.of(renderObject);
    final offset = viewport.getOffsetToReveal(renderObject, alignment).offset;
    if (offset.isFinite) { // all good so we've got a proper scroll to do
      await _verticalScrollController.animateTo(
        offset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else  { // final attempt - at least we make sure it's somewhere on the screen
      Scrollable.ensureVisible(
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        keyContext,
        alignment: alignment,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }


  void _toggleOnlyNowOrSoon() {
    final newonlyNowOrSoon = !widget.onlyNowOrSoon;
    widget.onFilterChange.call(newonlyNowOrSoon, widget.filteredMusicOrNot);
    if (mounted) setState(() { });
    Fluttertoast.showToast(
      msg: (newonlyNowOrSoon) ? 'Only showing what’s on now or starting soon' : 'Showing everything',
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
      fontSize: 16,
      toastLength: Toast.LENGTH_SHORT,
      timeInSecForIosWeb: 2,
    );
  }


  void _toggleFilteredMusicOrNot() {
    debugPrint('_TimetablePageState _toggleFilteredMusicOrNot called with widget.filteredMusicOrNot=$widget.filteredMusicOrNot');
    bool? newFilteredMusicOrNot;
    String theMsg;
    (theMsg, newFilteredMusicOrNot) = switch(widget.filteredMusicOrNot) {
      null => ('Showing only music performances', true),
      true => ('Showing everything but music performances', false),
      false => ('Showing all performances', null)
    };
    if (mounted) setState(() { });
    widget.onFilterChange.call(widget.onlyNowOrSoon, newFilteredMusicOrNot);
    Fluttertoast.showToast(
      msg: theMsg,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
      fontSize: 16,
      toastLength: Toast.LENGTH_SHORT,
      timeInSecForIosWeb: 2,
    );
    debugPrint('_TimetablePageState _toggleFilteredMusicOrNot called with widget.filteredMusicOrNot=$widget.filteredMusicOrNot');
  }


  @override
  Widget build(BuildContext context) {

    if (!scaling) debugPrint('_TimetablePageState build called with loading=$loading filteredMusicOrNot=${widget.filteredMusicOrNot} onlyNowOrSoon=${widget.onlyNowOrSoon}');
    if (loading) {
      return FairScaffold(
        appBarTitle: 'Timetable',
        currentTab: 2,
        onTabSelected: widget.onTabSelected,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.onlyNowOrSoon != _onlyNowOrSoonSaved || widget.filteredMusicOrNot != _filteredMusicOrNotSaved) {
      // refilter to whole day or just now or soon; only do this if changed
      _onlyNowOrSoonSaved = widget.onlyNowOrSoon;
      _filteredMusicOrNotSaved = widget.filteredMusicOrNot;
      theFilteredEvents = filterEventsAndComputeDefaults(thePreparedEvents, widget.onlyNowOrSoon, widget.filteredMusicOrNot, _searchQuery);
    }
    calculateInitialScalesIfNeeded();
    if (fairDate.difference(DateTime.now()).inDays == 0 && timelineMinStart.isBefore(DateTime.now()) && timelineMaxEnd.isAfter(DateTime.now())) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_nowLineTimer == null) startClockUpdates(updateNowLine);
        if (!widget.onlyNowOrSoon && _searchQuery.isEmpty) scrollToKey(nowLineKey, 0.3);
      });
    } else if (_searchQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verticalScrollController.animateTo(0, duration: Duration(milliseconds: 100), curve: Curves.easeIn);
      });
    }

    String theErrorMessage = '';
    if (spanMinutes == 0 || theFilteredEvents.isEmpty) {
      theErrorMessage = 'Nothing to show.';
      if (widget.onlyNowOrSoon) theErrorMessage += '\n\nUnselect ‘now or soon’ to see the whole day.';
      if (_searchQuery != '') theErrorMessage += '\n\nYou can clear your search by tapping the X icon in the search bar.';
    }

    final now = DateTime.now();
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final colorScheme = Theme.of(context).colorScheme;
    final appBarTheme = Theme.of(context).appBarTheme;
    double startPixelsPerMinute; // for pinch scaling
    final int markInterval = pixelsPerMinuteP >= 1.4 ? 30 : 60;
    final List<Widget> markers = [];
    final List<Widget> swimlanes = [];
    final nowOrSoonIconKey = GlobalKey();
    final subcategoryIconKey = GlobalKey();
    final searchIconKey = GlobalKey();

    return FairScaffold(
      appBarTitle: "Timetable",
      currentTab: 2,
      onTabSelected: widget.onTabSelected,
      appBarActions: [
        IconButton(
          key: nowOrSoonIconKey,
          onLongPress: () => showMiniPopup(context, nowOrSoonIconKey, 'Tap to switch between showing everything and showing just what’s on now or starting soon'),
          onPressed: () => (isItEventDay())
            ? _toggleOnlyNowOrSoon()
            : showMiniPopup(context, nowOrSoonIconKey, '‘Now or soon’ is only available when the Fair is underway', colorScheme.error),
          icon: Icon(
            (widget.onlyNowOrSoon) ? Icons.schedule : Icons.schedule, 
            color: (isItEventDay()) ? appBarTheme.foregroundColor : appBarTheme.foregroundColor!.withAlpha(130),
          ),
        ),
        IconButton(
          key: subcategoryIconKey,
          color: appBarTheme.foregroundColor,
          onLongPress: () => showMiniPopup(context, subcategoryIconKey, 'Tap to switch between showing just music, everything but music, or everything'),
          onPressed: () {
            HapticFeedback.lightImpact();
            _toggleFilteredMusicOrNot();
            theFilteredEvents = filterEventsAndComputeDefaults(thePreparedEvents, widget.onlyNowOrSoon, widget.filteredMusicOrNot, _searchQuery);
          },
          icon: Icon(switch (widget.filteredMusicOrNot) { false => Icons.music_off, true => Icons.music_note, null => Icons.filter_alt }, size: 26),
        ),
        IconButton(
          key: searchIconKey,
          color: colorScheme.onSecondary,
          onLongPress: () => showMiniPopup(context, searchIconKey, (_isSearching) ? 'Tap to close the search bar and cancel your search' : 'Tap to open the search bar'),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
                theFilteredEvents = filterEventsAndComputeDefaults(thePreparedEvents, widget.onlyNowOrSoon, widget.filteredMusicOrNot, _searchQuery);
              }
            });
          },
          icon: Icon((_isSearching) ? Icons.search_off : Icons.search, size: 26, color: appBarTheme.foregroundColor),
        ),
      ],
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: favouriteListingKeys,
        builder: (context, name, child) {
          return LayoutBuilder(
            builder: (context, constraints) {

              totalWidth = max(MediaQuery.sizeOf(context).width, theFilteredEvents.length * 100.0 + leftColumnWidth) - 2.0; // empirically the min size to fit whole times

              if (!scaling) {
                final currentOrientation = MediaQuery.orientationOf(context);
                if (widget.onlyNowOrSoon) {
                  _dayPixelsPerMinute = max(0.8, min(20, (constraints.maxHeight - 48) / max(spanMinutes, 30)));
                } else {
                  if (currentOrientation == Orientation.landscape) {
                    _dayPixelsPerMinute = pixelsPerMinuteL; // the local version which may have changed from that in schedule
                  } else {
                    _dayPixelsPerMinute = pixelsPerMinuteP; // the local version which may have changed from that in schedule
                  }
                }
              }
              startPixelsPerMinute = _dayPixelsPerMinute;
              final cols = theFilteredEvents.length;
              // prepare lanes for each location
              final Map<String, List<PositionedEvent>> positioned = {};
              final columnWidth = (totalWidth - leftColumnWidth) / cols;
              for (var loc in theFilteredEvents.keys) {
                final evs = theFilteredEvents[loc];
                positioned[loc] = computeLanes(evs!, timelineMinStart, _dayPixelsPerMinute, columnWidth);
              }

              // Build the pale grey 'swim lanes'
              for (int i = 0; i < cols; i++) {
                swimlanes.add(
                  Positioned(
                    top: 0,
                    left: 12 + leftColumnWidth + i * (totalWidth - leftColumnWidth) / cols,
                    height: spanMinutes * _dayPixelsPerMinute + 8,
                    child: Container(color: colorScheme.surfaceDim, width: (totalWidth - leftColumnWidth) / cols - 22),
                  ),
                );
              }

              // Build time markers (every 30 or 60 minutes depending on span)
              DateTime t = DateTime(
                timelineMinStart.year, 
                timelineMinStart.month, 
                timelineMinStart.day, 
                timelineMinStart.hour, 
                (timelineMinStart.minute ~/ markInterval + 1) * markInterval
              );
              while (t.isBefore(timelineMaxEnd.add(Duration(minutes: markInterval)))) {
                final top = max(0.0, t.difference(timelineMinStart).inMinutes * _dayPixelsPerMinute);
                final timeLabel = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
                markers.add(
                  Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    child: Container(height: 1, color: colorScheme.surfaceDim),
                  ),
                );
                markers.add(
                  Positioned(
                    top: top - 8,
                    left: 6,
                    child: Text(
                      timeLabel, 
                      style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.bold, 
                        color: colorScheme.onSurfaceVariant, 
                        shadows: [Shadow(color: colorScheme.onPrimary, offset: Offset(0, 0), blurRadius: 2)],
                      ),
                    ),
                  ),
                );
                t = t.add(Duration(minutes: markInterval));
              }

              final nowTop = max(0.0, (now.difference(timelineMinStart).inMinutes) * _dayPixelsPerMinute) - 1.5;
              final timelineHeight = max(constraints.maxHeight - 40, spanMinutes * _dayPixelsPerMinute + 4);
              final theContent = Column(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isSearching ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        key: const ValueKey('searchBar'),
                        color: colorScheme.surfaceDim,
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width, maxHeight: 52),
                        padding: EdgeInsets.all(8),
                        child: SearchBar(
                          autoFocus: true,
                          controller: _searchController,
                          elevation: const WidgetStatePropertyAll(0),
                          hintText: 'Search all events...',
                          leading: const Icon(Icons.search),
                          trailing: [
                            IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  if (_searchQuery.isEmpty) _isSearching = false; // first click clears field; second closes search
                                  _searchQuery = '';
                                  _searchController.clear();
                                  theFilteredEvents = filterEventsAndComputeDefaults(thePreparedEvents, widget.onlyNowOrSoon, widget.filteredMusicOrNot, _searchQuery);
                                });
                              },
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                              theFilteredEvents = filterEventsAndComputeDefaults(thePreparedEvents, widget.onlyNowOrSoon,widget.filteredMusicOrNot, _searchQuery);
                            });
                          },
                        ),
                      ),
                    ],
                  ) : SizedBox.shrink(),
                ),
                (theErrorMessage != '') 
                  ? Align(alignment: Alignment.center, child: Padding(padding: EdgeInsetsGeometry.all(60), child: Text(theErrorMessage, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)))
                  : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification || notification is UserScrollNotification) {
                      removeMiniPopup();
                    }
                    return false; // let scrolling continue
                  },
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(right: 2), // stop it crashing into edge
                    child: SizedBox(
                      width: totalWidth,
                      child: Column(
                        children: [
                          // Fixed header row
                          Container(
                            color: colorScheme.surfaceContainerLowest,
                            height: 34,
                            child: Row(spacing: 4,
                              children: [
                                Container(width: leftColumnWidth - 2), 
                                for (final location in positioned.entries)
                                  Builder(builder: (itemContext) {
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        showMiniPopup(itemContext, null, location.key);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.onSurfaceVariant,
                                          border: Border.all(width: 0.1),
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                                        ),
                                        width: (totalWidth - leftColumnWidth) / cols - 4,
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        alignment: AlignmentGeometry.center,
                                        child: AutoSizeText(
                                          location.key,
                                          softWrap: true,
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                                          minFontSize: 11,
                                          maxFontSize: 15,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          // Scrollable timeline content
                          SizedBox(
                            height: constraints.maxHeight - 34 - (_isSearching ? 56 : 0),
                            child: GestureDetector(
                              onScaleStart: (details) {
                                if (widget.onlyNowOrSoon || details.pointerCount < 2) return; // ignore drags
                                scaling = true;
                                startPixelsPerMinute = _dayPixelsPerMinute;
                              },
                              onScaleUpdate: (details) {
                                if (widget.onlyNowOrSoon || details.pointerCount < 2) return; // ignore drags
                                final dampenedScale = 1 + (details.scale - 1) * 0.5;
                                final newdayPixelsPerMinute = max(((constraints.maxHeight - 40) / spanMinutes), min(1.5, startPixelsPerMinute * dampenedScale));
                                if (newdayPixelsPerMinute != _dayPixelsPerMinute) {
                                  setState(() {
                                    _dayPixelsPerMinute = max(((constraints.maxHeight - 40) / spanMinutes), min(1.5, startPixelsPerMinute * dampenedScale));
                                  });
                                }
                              },
                              onScaleEnd: (_) async {
                                if (scaling) {
                                  scaling = false;
                                  if (!widget.onlyNowOrSoon) { // don't save special 'now' scale
                                    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
                                      if (_dayPixelsPerMinute != pixelsPerMinuteL) { // only saved if genuinely changed
                                        pixelsPerMinuteL = _dayPixelsPerMinute;
                                        saveScales();
                                      }
                                    } else {
                                      if (_dayPixelsPerMinute != pixelsPerMinuteP) { // only saved if genuinely changed
                                        pixelsPerMinuteP = _dayPixelsPerMinute;
                                        saveScales();
                                      }
                                    }
                                  }
                                  setState(() { });
                                }
                              },
                              child: SingleChildScrollView(
                                controller: _verticalScrollController,
                                physics: const ClampingScrollPhysics(),
                                scrollDirection: Axis.vertical,
                                key: PageStorageKey('verticalList'),
                                child: SizedBox(
                                  width: totalWidth,
                                  height: timelineHeight,
                                  child: Stack(
                                    children: [
                                      // time markers lines and labels and swim lanes
                                      ...swimlanes,
                                      // red 'now' line
                                      if (timelineMinStart.isBefore(DateTime.now()) && timelineMaxEnd.isAfter(DateTime.now()))
                                        Positioned(
                                          key: nowLineKey,
                                          top: nowTop,
                                          left: 0,
                                          right: 0,
                                          child: Container(height: 3, color: Colors.red),
                                        ),
                                      ...markers,
                                      // Event stacks per column
                                      Positioned(
                                        top: 0,
                                        left: leftColumnWidth,
                                        right: 0,
                                        child: SizedBox(
                                          height: timelineHeight,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              for (final location in positioned.entries)
                                                SizedBox(
                                                  width: (totalWidth - leftColumnWidth) / cols,
                                                  height: timelineHeight,
                                                  child: Stack(
                                                    children: [
                                                      // For each event in this location, place positioned containers
                                                      for (var pe in location.value) ...[
                                                        (scaling)
                                                          ? Positioned(
                                                            top: pe.top,
                                                            left: pe.left,
                                                            width: pe.width,
                                                            height: pe.height,
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                color: colorScheme.secondary,
                                                                borderRadius: BorderRadius.circular(4),
                                                                boxShadow: [BoxShadow(color: colorScheme.surfaceContainerLow, offset: Offset(2, 2), blurRadius: 3)],
                                                                border: Border.all(width: 0.2, color: colorScheme.surfaceContainerHighest),
                                                              )
                                                            )
                                                          )
                                                          : Positioned(
                                                            top: pe.top,
                                                            left: pe.left,
                                                            width: pe.width,
                                                            height: pe.height,
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                HapticFeedback.lightImpact();
                                                                showListingDetailsDialog(
                                                                  context, 
                                                                  pe, 
                                                                  //alertNoticePeriod,
                                                                  setState,
                                                                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => MapPage(
                                                                    listings: listings, 
                                                                    onTabSelected: (_) => {}, 
                                                                    destinationId: pe.id,
                                                                    destinationLatLng: pe.latLng,
                                                                  ))),
                                                                );
                                                              },
                                                              child: Container(
                                                                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 1),
                                                                decoration: BoxDecoration(
                                                                  color: (favouriteListingKeys.value.contains(pe.id)) ? colorScheme.primary.withAlpha(40) : colorScheme.onPrimary,
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  boxShadow: [BoxShadow(color: colorScheme.surfaceContainerLow, offset: Offset(2, 2), blurRadius: 3)],
                                                                  border: Border.all(width: 0.2, color: colorScheme.onSecondary),
                                                                ),
                                                                child: eventRect(pe, colorScheme, isLandscape, null),
                                                              ),
                                                            ),
                                                          ),
                                                        if (!scaling && favouriteListingKeys.value.contains(pe.id)) Positioned(
                                                          top: pe.top + 2,
                                                          left: pe.left + pe.width - 18,
                                                          child: Icon(Icons.favorite, size: 16, color: Colors.red.withAlpha(120)),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
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
                ),
              ]);
              return theContent;
            }
          );
        }
      )
    );
  }
}


