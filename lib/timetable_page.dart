import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:mill_road_winter_fair_app/android_nav_bar_detector.dart';
import 'package:mill_road_winter_fair_app/globals.dart';

class TimetablePage extends StatefulWidget {
  final List<Map<String, dynamic>> theEvents;
  final Set<String> favouriteListingKeys;
  const TimetablePage({
    required this.theEvents,
    required this.favouriteListingKeys,
    super.key,
  });
  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  Timer? _nowLineTimer;
  final nowLineKey = GlobalKey();
  late double _dayPixelsPerMinute; // scale for the current day view, whatever its orientation
  late double pixelsPerMinuteL, pixelsPerMinuteP; // orientation-specific scales
  Orientation? _deviceOrientationSaved; // to track if this has changed
  bool scaling = false; // tracks whether user is re-scaling the view
  bool onlyNowOrSoon = false; // whether to show what's on now or soon
  bool? _onlyNowOrSoonSaved; // to track if this has changed
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
  OverlayEntry? _miniPopupOverlayEntry; // 
  Timer? _miniPopupTimer;
  Route? listingDetailsDialogRoute; // to keep track of dialog so it can be closed if needed. This will move to main if we enter the app from an alert

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
/*TODOif (isThisToday(widget.day.key) && widget.day.minStart.isBefore(DateTime.now()) && widget.day.maxEnd.isAfter(DateTime.now())) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startClockUpdates(updateNowLine);
      });
    } */
    thePreparedEvents = prepareEvents(widget.theEvents);
    loadScales();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _nowLineTimer?.cancel();
    super.dispose();
  }

  @override
  // so app knows if the device has been rotated, and can restore any previous scroll/sizing
  void didChangeDependencies() {
    debugPrint('_TimetablePageState didChangeDependencies called');
    final Orientation currentOrientation = MediaQuery.orientationOf(context);
    if (_deviceOrientationSaved !=null && currentOrientation != _deviceOrientationSaved) { // i.e. device has been rotated (or this is the first check)
      if (_deviceOrientationSaved != null) debugPrint('DayTimelineViewState didChangeDependencies: changed orientation, _deviceOrientation=$_deviceOrientationSaved currentOrientation=$currentOrientation');
      removeMiniPopup();
      //TODOsafeRemoveRoute(context, sHRADDialogRoute);
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
    debugPrint('_TimetablePageState calculateInitialScalesIfNeeded called');
    if (pixelsPerMinuteP == 0 || pixelsPerMinuteL == 0) {
      debugPrint('_TimetablePageState calculateInitialScalesIfNeeded estimating initial scale');
      pixelsPerMinuteP = max(0.8, min(1.5, 1000 / max(240, spanMinutes)));
      pixelsPerMinuteL = max(0.8, min(1.5, 600 / max(240, spanMinutes)));
      saveScales();
    }
  }


  Future<void> _saveFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favouritesList', favouriteListingKeys.toList());
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
    debugPrint('DayTimelineViewState startClockUpdates started initially $initialDelay then every $delay for function $tick');
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
      if (((ev['performance'] != null && ev['performance'] == 'TRUE') || (ev['music'] != null && ev['music'] == 'TRUE') || (ev['event'] != null && ev['event'] == 'TRUE'))
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
          emoji: ev['emoji'],
          description: ev['description'],
          latLng: ev['latLng'],
          imageURL: ev['imageURL'],
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


  Map<String, List<PositionedEvent>> filterEventsAndComputeDefaults(Map<String, List<PositionedEvent>> theEvents, bool onlyNowOrSoon) {
    timelineMinStart = DateTime(9999);
    timelineMaxEnd = DateTime(0);
    final now = DateTime.now();
    Map<String, List<PositionedEvent>> theFilteredEvents = {};
    for (final location in theEvents.entries) {
      final theEventsAtThisLocation = location.value;
      for (int i=0; i<theEventsAtThisLocation.length; i++) {
        final ev = theEventsAtThisLocation[i];
        if (!onlyNowOrSoon 
            || (ev.startTime.isBefore(now) && ev.endTime.difference(now).inMinutes >= -10) 
            || (ev.startTime.isAfter(now) && (ev.startTime.difference(now).inMinutes <= 60))) {
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
      pe.left = pe.lane * laneWidth + laneGap / 2;
      pe.width = max(8, laneWidth - laneGap);
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


  String formatTimeRange(DateTime startTime, DateTime endTime) {
  return '${startTime.hour.toString().padLeft(2,'0')}:${startTime.minute.toString().padLeft(2,'0')}–'
    '${endTime.hour.toString().padLeft(2,'0')}:${endTime.minute.toString().padLeft(2,'0')}';
  }


  void scrollToKey(GlobalKey theKey, double alignment) async {
    debugPrint('DayTimelineViewState scrollToKey called with theKey=$theKey alignment=$alignment');
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


  void showMiniPopup(BuildContext itemContext, GlobalKey? theKey, String theMessage, [Color? fgColour, Color? bgColour]) {

    fgColour ??= Theme.of(itemContext).colorScheme.secondary;
    bgColour ??= Theme.of(itemContext).colorScheme.onSecondary;

    removeMiniPopup();

    final overlay = Overlay.of(itemContext);
    final RenderBox box;
    if (theKey == null) {
      box = itemContext.findRenderObject() as RenderBox;
    } else {
      box = theKey.currentContext?.findRenderObject() as RenderBox;
    }
    final itemTopLeft = box.localToGlobal(Offset.zero);
    final itemSize = box.size;
    final screenWidth = MediaQuery.sizeOf(itemContext).width;
    final overlayW = min(max(theMessage.length / 0.25, 155.0), 230.0);
    final theStyle = TextStyle(fontSize: 13.0, decoration: TextDecoration.none, fontWeight: FontWeight.normal, color: fgColour);
    final overlayH = estimateTextHeight(text: theMessage, style:theStyle, maxWidth:overlayW, context: itemContext);
    const gap = 4.0;
    final theDuration = (theMessage.length / 25).toInt() + 2;

    // Prefer placing the box above the item, otherwise below.
    double desiredTop = itemTopLeft.dy - overlayH - gap - 8.0; // box padding
    if (desiredTop < MediaQuery.paddingOf(itemContext).top + 4) {
      desiredTop = itemTopLeft.dy + itemSize.height + gap;
    }
    // Horizontal: try to centre above the item
    double desiredLeft = itemTopLeft.dx + itemSize.width / 2 - overlayW / 2;
    if (desiredLeft < 4) desiredLeft = 4;
    if (desiredLeft + overlayW > screenWidth - 4) desiredLeft = screenWidth - overlayW - 4;
    _miniPopupOverlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: desiredLeft,
        top: desiredTop,
        child: GestureDetector( // since field may be clipped
          onTap: () {
            HapticFeedback.lightImpact();
            removeMiniPopup();
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: overlayW, // wrapping boundary
            ),
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: bgColour,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: bgColour!, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Text(theMessage, softWrap: true,
                style: theStyle),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_miniPopupOverlayEntry!);
    _miniPopupTimer = Timer(Duration(seconds: theDuration), () => removeMiniPopup());

  }


  void removeMiniPopup() {
    _miniPopupTimer?.cancel();
    _miniPopupTimer = null;
    if (_miniPopupOverlayEntry != null) {
      try {
        _miniPopupOverlayEntry!.remove();
      } catch (_) {}
      _miniPopupOverlayEntry = null;
    }
  }


  double estimateTextHeight({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required BuildContext context,
    int? maxLines,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      strutStyle: StrutStyle.fromTextStyle(style)
    )..layout(maxWidth: maxWidth);
    return tp.size.height;
  }


  void favouriteOrNotListing(PositionedEvent theEvent) {
    if (favouriteListingKeys.contains(theEvent.id)) {
      favouriteListingKeys.remove(theEvent.id);
    } else {
      favouriteListingKeys.add(theEvent.id);
    }
    setState(() {});
    _saveFavourites();
  }


  Future<void> showListingDetailsDialog(
    BuildContext context, 
    PositionedEvent event, 
    //int alertNoticePeriod,
    void Function(VoidCallback) setStateFunction,
//    final int? Function(PositionedEvent, int, int?) toggleAlertAction,
  ) async {

    debugPrint('showListingDetailsDialog called');

    removeMiniPopup(); // just in case one was opened

    if (!context.mounted) return;
    final colorScheme = Theme.of(context).colorScheme;

    listingDetailsDialogRoute = DialogRoute(context: context, barrierColor: Colors.black38, builder: (_) => StatefulBuilder(
      builder: (ctx2, setStateDialog) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 8), // margin from screen edges
          shape: RoundedRectangleBorder(side: BorderSide(color: colorScheme.onSecondary, width: 0.5), borderRadius: BorderRadius.circular(12)),
          backgroundColor: colorScheme.surfaceContainerLowest,
          shadowColor: colorScheme.surfaceContainerHighest,
          elevation: 12,
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              width: 288,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: listingDetailsColumn(
                context, 
                event, 
                //alertNoticePeriod,
                setStateFunction,
                setStateDialog,
//                toggleAlertAction,
              ),
            ),
          ),
        );
      },
    ));
    await Navigator.of(context).push(listingDetailsDialogRoute!);
    removeMiniPopup(); // just in case one was opened

  }


  Widget listingDetailsColumn(
    BuildContext context, 
    PositionedEvent event, 
    //int alertNoticePeriod,
    void Function(VoidCallback) setParentStateFunction, // calling page (if dialog) otherwise local page
    void Function(VoidCallback)? setLocalStateFunction, // dialog if we're in one
    //final int? Function(PositionedEvent, int, int?) toggleAlertAction,
  )  {

    final eventNameTextKey = GlobalKey(); // for mini pop-ups
    final eventNameDescKey = GlobalKey(); // for mini pop-ups
    //final notificationKey = GlobalKey(); // for mini pop-ups
    final colorScheme = Theme.of(context).colorScheme;
    ButtonStyle buttonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(colorScheme.secondary), 
      foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 2, vertical: 0)), 
      elevation: WidgetStatePropertyAll(3),
      visualDensity: VisualDensity(horizontal: -3.0, vertical: -3),
      shadowColor: WidgetStatePropertyAll(colorScheme.surfaceContainerLow),
      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14.0)),
    );
    final textStyle = TextStyle(fontSize: 16.0, height: 1.2);
    final now = DateTime.now();
    final pastEvent = (event.startTime.difference(now).inMinutes < 0);
    final tooLongFutureEvent = (event.startTime.difference(now).inDays > 7);
    //final theAlertsStore = theScheduleHomeState.alertsStore;
    //int? alertId = theAlertsStore.alertIdForEvent(event);
    bool settingsOpened = false; // keeps track of permissions dialog being opened so we can re-check

    debugPrint('listingDetailsColumn called');

/*     void setTheAlert(StateSetter setStateDialog, [int? noticePeriod]) async {
      removeMiniPopup();
      if (settingsOpened) { // button previously tapped when alert permissions weren't given; maybe they are now
        alertsPermissionGranted = await requestAlertPermissions();
        settingsOpened = false;
      }
      if (alertsPermissionGranted) {
        alertId = toggleAlertAction.call(event, noticePeriod ?? alertNoticePeriod, alertId);
        setParentStateFunction.call(() => {});
        setLocalStateFunction?.call(() => {});
      } else {
        alertsPermissionGranted = await requestAlertPermissions();
        if (!alertsPermissionGranted) {
          settingsOpened = true;
          if (context.mounted) await showNoPermissionsDialog(context, colorScheme);
        } else {
          alertId = toggleAlertAction.call(event, noticePeriod ?? alertNoticePeriod, alertId);
          if (context.mounted) setParentStateFunction.call(() => {});
          if (context.mounted) setLocalStateFunction?.call(() => {});
        }
      }
    } */

/*     Map<String, void Function()> alertOptions = {};
    if (event.start.difference(now).inMinutes > 60) alertOptions['60 minutes before'] = () => setTheAlert(setParentStateFunction, 60);
    if (event.start.difference(now).inMinutes > 30) alertOptions['30 minutes before'] = () => setTheAlert(setParentStateFunction, 30);
    if (event.start.difference(now).inMinutes > 15) alertOptions['15 minutes before'] = () => setTheAlert(setParentStateFunction, 15);
    if (event.start.difference(now).inMinutes > 5) alertOptions['5 minutes before'] = () => setTheAlert(setParentStateFunction, 5);
    if (event.start.difference(now).inMinutes > 0) alertOptions['At time of event'] = () => setTheAlert(setParentStateFunction, 0);
 */
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8.0,
          children: [
            Row(spacing: 10, mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(width: 28, height: 28, child: Text(event.emoji, style: textStyle.copyWith(fontSize: 24, height: 1.2), textAlign: TextAlign.center)),
              Expanded(child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector( // since field may be clipped
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showMiniPopup(context, eventNameTextKey, event.name);
                    },
                    child: Text(
                      event.name, 
                      style: TextStyle(fontSize: 18.0, height: 1.2, fontWeight: FontWeight.bold), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis, 
                      key: eventNameTextKey
                    ),
                  );
                }
              )),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  favouriteOrNotListing(event);
                  setStateDialog(() {});
                },
                padding: const EdgeInsets.all(0),
                style: ElevatedButton.styleFrom(visualDensity: const VisualDensity(horizontal: -4, vertical: -4), padding: const EdgeInsets.all(0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                icon:Icon(
                  (favouriteListingKeys.contains(event.id)) ? Icons.favorite : Icons.favorite_border_outlined, 
                  shadows: [Shadow( color: Theme.of(context).shadowColor, offset: const Offset(1, 3), blurRadius: 5)],
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
            ],),
            if (event.subtitle != '') Row(spacing: 10, children: [
              SizedBox(width: 28, height: 28, child: Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant)),
              SizedBox(width: 218, child: AutoSizeText(event.subtitle, style: textStyle, maxLines: 2)),
            ]),
            Row(spacing: 10, children: [
              SizedBox(width: 28, height: 28, child: Icon(Icons.access_time, color: colorScheme.onSurfaceVariant)),
              Expanded(
                child: AutoSizeText(formatTimeRange(event.startTime, event.endTime), style: textStyle)
              ),
/*               SizedBox(width: 30, height: 30, child: ElevatedButton(
                key: notificationKey,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor:  (alertId != null) ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                  elevation: (alertId != null || pastEvent || tooLongFutureEvent) ? 0 : 4,
                  shadowColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onLongPress: pastEvent ? () => showMiniPopup(context, notificationKey, 'Can’t set an alert for something in the past!', Theme.of(context).colorScheme.error)
                  : tooLongFutureEvent ? () => showMiniPopup(context, notificationKey, 'Alerts can only be set within the week before the event', Theme.of(context).colorScheme.error)
                  : (alertOptions.isNotEmpty && alertId == null) ? () => showMiniMenuOverlay(context, null, notificationKey, alertOptions, true)
                  : (alertId != null) ? () => showMiniPopup(context, notificationKey, 'Tap to cancel alert, then optionally long-press to choose a custom notice period')
                  : null,
                onPressed: pastEvent ? () => showMiniPopup(context, notificationKey, 'Can’t set an alert for something in the past!', Theme.of(context).colorScheme.error)
                  : tooLongFutureEvent ? () => showMiniPopup(context, notificationKey, 'Alerts can only be set within the week before the event', Theme.of(context).colorScheme.error)
                  : () async {
                    HapticFeedback.lightImpact();
                    setTheAlert(setParentStateFunction);
                  },
                child: (pastEvent || tooLongFutureEvent)
                  ? SvgPicture.asset('assets/icons/alertOff.svg', width: 20)
                  : SvgPicture.asset('assets/icons/alert.svg', width: 20),
              )), */
            ]),
            Row(spacing: 10, mainAxisAlignment: MainAxisAlignment.start, key: eventNameDescKey, children: [
              SizedBox(width: 28, height: 28, child: Icon(Icons.location_on_outlined, size: 28, color: colorScheme.onSurfaceVariant)),
              SizedBox(width: 218, child: AutoSizeText(event.location, style: textStyle, maxLines: 2)),
            ]),
            if (event.description != '') Row(spacing: 10, crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 28, height: 28, child: Icon(Icons.description_outlined, size: 28, color: colorScheme.onSurfaceVariant)),
              SizedBox(width: 218, child: GestureDetector( // since field may be clipped
                onTap: () {
                  HapticFeedback.lightImpact();
                  showMiniPopup(context, eventNameDescKey, event.description);
                },
                child: AutoSizeText(event.description, style: textStyle, maxLines: 5, minFontSize: 13, overflow: TextOverflow.ellipsis),
              )),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              ElevatedButton(
                style: buttonStyle,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  safeRemoveRoute(context, listingDetailsDialogRoute); // doing this not pop as we may be in landscape itinerary view
                }, 
                child: Text('Close'),
              ),
            ],),
          ],
        );
      }
    );
  }


  // Safe route removal with null/active checks
  void safeRemoveRoute(BuildContext context, Route? route) {
    if (route != null && route.isActive && route.navigator != null) {
      try {
        Navigator.of(context).removeRoute(route);
      } catch (e) {
        debugPrint('safeRemoveRoute: error removing route: $e');
      }
    }
}


  @override
  Widget build(BuildContext context) {

    debugPrint('_TimetablePageState build called with loading=$loading');
    if (loading) return Scaffold(body: Center(child: CircularProgressIndicator()));

    if (onlyNowOrSoon != _onlyNowOrSoonSaved) {
      // refilter to whole day or just now or soon
      _onlyNowOrSoonSaved = onlyNowOrSoon;
      theFilteredEvents = filterEventsAndComputeDefaults(thePreparedEvents, onlyNowOrSoon);
    }
    calculateInitialScalesIfNeeded();

    if (spanMinutes == 0 || theFilteredEvents.isEmpty) {
      String theMessage = 'Nothing to show.';
      if (onlyNowOrSoon) theMessage += '\n\nUnselect ‘now or soon’\nto see the whole day.';
      return Align(alignment: AlignmentGeometry.center, 
        child: Text(theMessage, style: TextStyle(fontSize: 16), textAlign: TextAlign.center)
      );
    }

    final now = DateTime.now();
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final colorScheme = Theme.of(context).colorScheme;
    double startPixelsPerMinute; // for pinch scaling
    final int markInterval = spanMinutes <= 6 * 60 ? 30 : 60;
    final List<Widget> markers = [];
    final List<Widget> swimlanes = [];

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid && isNavBarVisible(context),
      child: LayoutBuilder(
      builder: (context, constraints) {

      totalWidth = max(MediaQuery.sizeOf(context).width, thePreparedEvents.length * 100.0 + leftColumnWidth) - 2.0; // empirically the min size to fit whole times

        if (!scaling) {
          final currentOrientation = MediaQuery.orientationOf(context);
          if (onlyNowOrSoon) {
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
              child: Container(color: colorScheme.primary.withAlpha(20), width: (totalWidth - leftColumnWidth) / cols - 22),
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
          final timeLabel = '${t.hour}:${t.minute}';
          markers.add(
            Positioned(
              top: top,
              left: 0,
              right: 0,
              child: Container(height: 1, color: colorScheme.surfaceContainerLow),
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
                  color: colorScheme.surfaceContainerHighest, 
                  shadows: [Shadow(color: colorScheme.onPrimary, offset: Offset(0, 0), blurRadius: 2)],
                ),
              ),
            ),
          );
          t = t.add(Duration(minutes: markInterval));
        }

        final nowTop = max(0.0, (now.difference(timelineMinStart).inMinutes) * _dayPixelsPerMinute) - 1.5;

        if (!onlyNowOrSoon && _onlyNowOrSoonSaved!) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToKey(nowLineKey, 0.3);
          });
        }
        _onlyNowOrSoonSaved = onlyNowOrSoon;

        final timelineHeight = max(constraints.maxHeight - 40, spanMinutes * _dayPixelsPerMinute + 4);
        final theContent = NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification || notification is UserScrollNotification) {
              //TODOremoveMiniHLsOverlay();
              //TODOremoveMiniPopup();
              //TODOremoveMiniMenuOverlay();
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
                    height: constraints.maxHeight - 34,
                    child: GestureDetector(
                      onScaleStart: (_) {
                        scaling = true;
                        startPixelsPerMinute = _dayPixelsPerMinute;
                      },
                      onScaleUpdate: (details) {
                        if (onlyNowOrSoon || details.pointerCount < 2) return; // ignore drags
                        final dampenedScale = 1 + (details.scale - 1) * 0.5;
                        setState(() {
                          _dayPixelsPerMinute = max(((constraints.maxHeight - 40) / spanMinutes), min(1.5, startPixelsPerMinute * dampenedScale));
                        });
                      },
                      onScaleEnd: (_) async {
                        scaling = false;
                        if (!onlyNowOrSoon) { // don't save special 'now' scale
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
                              ...markers,
                              if (timelineMinStart.isBefore(DateTime.now()) && timelineMaxEnd.isAfter(DateTime.now()))
                                Positioned(
                                  key: nowLineKey,
                                  top: nowTop,
                                  left: 0,
                                  right: 0,
                                  child: Container(height: 3, color: Colors.red),
                                ),
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
                                              for (var pe in location.value)
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
                                                  child: Builder(
                                                    builder: (itemContext) {
                                                      final isFavourited = favouriteListingKeys.contains(pe.id);
                                                      return GestureDetector(
                                                        onTap: () {
                                                          HapticFeedback.lightImpact();
/*                                                           showHighlightsRatingsAndDetailsDialog(
                                                            itemContext, 
                                                            pe.event, 
                                                            widget.parentState, 
                                                            (MediaQuery.orientationOf(context) == Orientation.landscape),
                                                            alertNoticePeriod,
                                                            widget.parentState.setState,
                                                            widget.showEventInDay,
                                                            widget.rateAction,
                                                            widget.toggleAlertAction,
                                                          ); */
                                                        },
                                                        onLongPress: () {
                                                          HapticFeedback.selectionClick;
/*                                                           showMiniHLsOverlay(
                                                            context, 
                                                            itemContext, 
                                                            pe.event, 
                                                            widget.parentState, 
                                                            widget.parentState.setState
                                                          ); */
                                                        },
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            HapticFeedback.lightImpact();
                                                            showListingDetailsDialog(
                                                              itemContext, 
                                                              pe, 
                                                              //alertNoticePeriod,
                                                              setState,
                                                            );
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 1),
                                                            decoration: BoxDecoration(
                                                              color: (isFavourited) ? colorScheme.primary.withAlpha(40) : colorScheme.onPrimary,
                                                              borderRadius: BorderRadius.circular(4),
                                                              boxShadow: [BoxShadow(color: colorScheme.surfaceContainerLow, offset: Offset(2, 2), blurRadius: 3)],
                                                              border: Border.all(width: 0.2, color: colorScheme.onSecondary),
                                                              image: (isFavourited)
                                                                ? DecorationImage(image: AssetImage('assets/icons/favorite_24dp_992F30.png'), scale: 1.5, alignment: AlignmentGeometry.topRight, opacity: 0.5) 
                                                                : null,
                                                            ),
                                                            child: eventRect(pe, colorScheme, isLandscape, null),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  ),
                                                ),
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
        );
        return theContent;
      }
    )
    );
  }
}


class PositionedEvent {
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String name;
  final String subtitle;
  final String id;
  final bool cancelled;
  final String emoji;
  final String description;
  final String latLng;
  final String imageURL;
  int lane;
  double top;
  double height;
  double left;
  double width;
  PositionedEvent({
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.name,
    required this.subtitle,
    required this.id,
    required this.cancelled,
    required this.emoji,
    required this.description,
    required this.latLng,
    required this.imageURL,
    required this.lane, 
    required this.top, 
    required this.height, 
    required this.left, 
    required this.width,
  });
}
