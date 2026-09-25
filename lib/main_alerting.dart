import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

bool alertsPermissionGranted = false; // whether the user has granted permission for notifications+alerts
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final notificationStream = StreamController<NotificationResponse>.broadcast();

Future<void> initialiseFlutterLocalNotificationsPlugin() async {
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(
    requestAlertPermission: true,
    notificationCategories: [
      DarwinNotificationCategory('UnderwayCategory', actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('show', 'Show', options: <DarwinNotificationActionOption>{DarwinNotificationActionOption.foreground}),
      ], options: <DarwinNotificationCategoryOption>{DarwinNotificationCategoryOption.hiddenPreviewShowTitle}),
      DarwinNotificationCategory('5MinsCategory', actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('snoozeStart', 'Snooze until start time'),
        DarwinNotificationAction.plain('show', 'Show', options: <DarwinNotificationActionOption>{DarwinNotificationActionOption.foreground}),
      ], options: <DarwinNotificationCategoryOption>{DarwinNotificationCategoryOption.hiddenPreviewShowTitle}),
      DarwinNotificationCategory('15MinsCategory', actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('snooze5mins', 'Snooze for 5 minutes'),
        DarwinNotificationAction.plain('snoozeStart', 'Snooze until start time'),
        DarwinNotificationAction.plain('show', 'Show', options: <DarwinNotificationActionOption>{DarwinNotificationActionOption.foreground}),
      ], options: <DarwinNotificationCategoryOption>{DarwinNotificationCategoryOption.hiddenPreviewShowTitle}),
      DarwinNotificationCategory('30MinsCategory', actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('snooze10mins', 'Snooze for 10 minutes'),
        DarwinNotificationAction.plain('snooze20mins', 'Snooze for 20 minutes'),
        DarwinNotificationAction.plain('snoozeStart', 'Snooze until start time'),
        DarwinNotificationAction.plain('show', 'Show', options: <DarwinNotificationActionOption>{DarwinNotificationActionOption.foreground}),
      ], options: <DarwinNotificationCategoryOption>{DarwinNotificationCategoryOption.hiddenPreviewShowTitle}),
      DarwinNotificationCategory('60MinsCategory', actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('snooze15mins', 'Snooze for 15 minutes'),
        DarwinNotificationAction.plain('snooze30mins', 'Snooze for 30 minutes'),
        DarwinNotificationAction.plain('snoozeStart', 'Snooze until start time'),
        DarwinNotificationAction.plain('show', 'Show', options: <DarwinNotificationActionOption>{DarwinNotificationActionOption.foreground}),
      ], options: <DarwinNotificationCategoryOption>{DarwinNotificationCategoryOption.hiddenPreviewShowTitle}),
    ]
  );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      notificationStream.add(notificationResponse);
     },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  if (Platform.isIOS) {
    final perms = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()!.checkPermissions();
    alertsPermissionGranted = perms != null && perms.isEnabled && perms.isAlertEnabled;
  }
  if (Platform.isAndroid) {
    final androidChannel = AndroidNotificationChannel(
      'org.millroadwinterfair.MRWFapp', // id
      'Event alerts', // name
      description: 'Mill Road Winter Fair event alerts',
      importance: Importance.high, // This triggers heads-up notification
      playSound: true,
      enableVibration: true,
    );
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);
  }
  final details = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (details?.didNotificationLaunchApp ?? false) notificationStream.add(details!.notificationResponse!);
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  // handle the alert action in an isolated process
  if (notificationResponse.payload == null || notificationResponse.id == null) {
    debugPrint('notificationTapBackground: invalid payload or id');
    return;
  }
  Map<String, dynamic> theEventAlert;
  try {
    theEventAlert = jsonDecode(notificationResponse.payload!);
  } catch (e) {
    debugPrint('notificationTapBackground: failed to decode payload: $e');
    return;
  }
  DateTime? startTime;
  try {
    startTime = DateTime.parse(theEventAlert['listingStartTime'] ?? '');
  } catch (e) {
    debugPrint('notificationTapBackground: failed to parse startTime: $e');
    return;
  }
  DateTime? newAlertTime;
  switch (notificationResponse.actionId) {
    case 'snooze5mins':
      newAlertTime = DateTime.now().add(Duration(minutes: 5));
    case 'snooze10mins':
      newAlertTime = DateTime.now().add(Duration(minutes: 10));
    case 'snooze15mins':
      newAlertTime = DateTime.now().add(Duration(minutes: 15));
    case 'snooze20mins':
      newAlertTime = DateTime.now().add(Duration(minutes: 20));
    case 'snooze30mins':
      newAlertTime = DateTime.now().add(Duration(minutes: 30));
    case 'snoozeStart':
      newAlertTime = [startTime, DateTime.now().add(Duration(minutes: 2))].reduce((a, b) => a.isAfter(b) ? a: b);
  }
  if (newAlertTime != null) {
    tz.initializeTimeZones();
    String? categoryID;
    List<AndroidNotificationAction> androidNotificationActions;
    String theMessage;
    final timeToGo = startTime.difference(newAlertTime).inMinutes;
    int noticePeriod;
    if (timeToGo <= 0) {
      categoryID = 'UnderwayCategory';
      androidNotificationActions = [AndroidNotificationAction('show', 'Show')];
      final endTime = DateTime.parse(theEventAlert['listingEndTime']);
      theMessage = '${theEventAlert['listingTitle']} underway at ${theEventAlert['listingLocation']} until ${intl.DateFormat('EEEE').format(endTime)}';
      noticePeriod = 0;
    } else {
      (categoryID, androidNotificationActions) = calculateAlertActionCategories(timeToGo);
      final startTime = DateTime.tryParse(theEventAlert['listingStartTime']);
          debugPrint('MW got ${theEventAlert['listingStartTime']} ${theEventAlert['listingTitle']} ${intl.DateFormat('EEEE').format(startTime!)}');
      theMessage = '${theEventAlert['listingTitle']} starting at ${theEventAlert['listingLocation']} in $timeToGo minutes${(startTime != null) ? ' (${intl.DateFormat.Hm().format(startTime)})' : ''}';
      noticePeriod = timeToGo;
    }
    flutterLocalNotificationsPlugin.cancel(id: notificationResponse.id!);
    DateTime? endTime;
    try {
      endTime = DateTime.parse(theEventAlert['listingEndTime'] ?? '');
    } catch (e) {
      debugPrint('notificationTapBackground: failed to parse endTime: $e');
      return;
    }
    final theAlert = AlertSchedule(
      notificationResponse.id!, 
      theEventAlert['listingId'],
      theEventAlert['listingTitle'],
      theEventAlert['listingLocation'],
      startTime, 
      endTime, 
      noticePeriod, 
      true, 
      null
    );
    flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationResponse.id!,
      title: 'Clashfinder Pal',
      body: theMessage,
      payload: jsonEncode(theAlert),
      scheduledDate: tz.TZDateTime.from(newAlertTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('org.millroadwinterfair.MRWFapp', 'Mill Road Winter Fair', actions: androidNotificationActions),
        iOS: DarwinNotificationDetails(threadIdentifier: 'org.millroadwinterfair.MRWFapp', categoryIdentifier: categoryID),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
    );
    debugPrint('onDidReceiveBackgroundNotificationResponse scheduled new alert for $newAlertTime with message “$theMessage”');
  }
}


(String, List<AndroidNotificationAction>) calculateAlertActionCategories(int theAlertNoticePeriod) {
  debugPrint('calculateAlertActionCategories with alertNoticePeriod=$theAlertNoticePeriod');
  switch (theAlertNoticePeriod) {
    case 0:
      return('UnderwayCategory', 
      []);
    case <= 10:
      return('5MinsCategory', [
        AndroidNotificationAction('snoozeStart', 'Snooze to start'),
      ]);
    case <= 19:
      return('15MinsCategory', [
        AndroidNotificationAction('snooze5mins', 'Snooze 5'),
        AndroidNotificationAction('snoozeStart', 'Snooze to start'),
      ]);
    case <= 35:
      return('30MinsCategory', [
        AndroidNotificationAction('snooze10mins', 'Snooze 10'),
        AndroidNotificationAction('snooze20mins', 'Snooze 20'),
        AndroidNotificationAction('snoozeStart', 'Snooze to start'),
      ]);
    default:
      return('60MinsCategory',[
        AndroidNotificationAction('snooze15mins', 'Snooze 15'),
        AndroidNotificationAction('snooze30mins', 'Snooze 30'),
        AndroidNotificationAction('snoozeStart', 'Snooze ’til start'),
      ]);
  }
}


Future<bool> requestAlertPermissions() async {
  debugPrint('requestAlertPermissions called with alertsPermissionGranted=$alertsPermissionGranted');
  late bool computeAlertsPermissionGranted;
  if (alertsPermissionGranted) return true;
   if (Platform.isAndroid) {
    final plugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (plugin == null) {
      debugPrint('requestAlertPermissions calling initialiseFlutterLocalNotificationsPlugin');
      await initialiseFlutterLocalNotificationsPlugin();
    }
    if (plugin == null) return false; // give up
    await plugin.requestExactAlarmsPermission();
    bool? areNotificationsEnabled = await plugin.areNotificationsEnabled();
    if (areNotificationsEnabled == null || !areNotificationsEnabled) {
      await plugin.requestNotificationsPermission();
      areNotificationsEnabled = await plugin.areNotificationsEnabled();
    }
    computeAlertsPermissionGranted = (areNotificationsEnabled ?? false);
    debugPrint('requestAlertPermissions Android returning with computeAlertsPermissionGranted=$computeAlertsPermissionGranted');
   } else if (Platform.isIOS) {
    final plugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (plugin == null) {
      debugPrint('requestAlertPermissions calling initialiseFlutterLocalNotificationsPlugin');
      await initialiseFlutterLocalNotificationsPlugin();
    } else {
      debugPrint('requestAlertPermissions calling plugin.requestPermissions');
      await plugin.requestPermissions(alert: true, providesAppNotificationSettings: true);
    }
    final perms = await plugin!.checkPermissions();
    computeAlertsPermissionGranted = (perms != null && perms.isEnabled && perms.isAlertEnabled);
    debugPrint('requestAlertPermissions iOS returning with perms=$perms isEnabled=${perms!.isEnabled} isAlertEnabled=${perms.isAlertEnabled}');
   } else { // some other platform we don't support
    computeAlertsPermissionGranted = false;
   }
   return computeAlertsPermissionGranted;
}


class AlertSchedule {

  final int id; // a unique ID for the alert, calculated internally
  final String listingId; // the unique ID of the listing
  final String listingTitle; // the readable name of the listing
  final String listingLocation; // the stage/venue of the listing
  DateTime listingStartTime; // its start time
  DateTime listingEndTime; // its end time
  int noticePeriod; // how many minutes in advance of the above the alert should show
  bool isScheduled; // whether this has actually been scheduled on the device
  bool? fromHighlight; // whether this was blanket-scheduled by highlight category

  AlertSchedule(
    this.id,
    this.listingId,
    this.listingTitle,
    this.listingLocation,
    this.listingStartTime,
    this.listingEndTime,
    this.noticePeriod, 
    this.isScheduled, 
    this.fromHighlight
  );

  // serialise to JSON for saving
  Map<String, dynamic> toJson() => _$AlertScheduleToJson(this);

  // convert from JSON for loading from saved
  factory AlertSchedule.fromJson(Map<String, dynamic> json) => _$AlertScheduleFromJson(json);

}


class AlertScheduleStore {

  final List<AlertSchedule> alertSchedules;
  int nextId;
  AlertScheduleStore(this.alertSchedules, this.nextId);

  // serialise to JSON for saving
  Map<String, dynamic> toJson() => _$AlertScheduleStoreToJson(this);

  // convert from JSON for loading from saved
  factory AlertScheduleStore.fromJson(Map<String, dynamic> json) => _$AlertScheduleStoreFromJson(json);

  factory AlertScheduleStore.initial() {
    return AlertScheduleStore([], 0);
  }

  AlertSchedule operator [](int index) => alertSchedules[index];

  bool alertExists(String listingId) => alertSchedules.any((a) => a.listingId == listingId);

  int? alertIdForListing(String listingId) => alertSchedules.firstWhereOrNull((a) => a.listingId == listingId)?.id;

  int addAlert(String listingId, int noticePeriod, bool isScheduled) {
    debugPrint('AlertScheduleStore addAlert for listingId=$listingId');
    final theListing = listings.firstWhereOrNull((l) => l['id'] == listingId);
    if (theListing == null) return -1;
    final newAlert = AlertSchedule(
      nextId,
      listingId,
      theListing['title'],
      theListing['location'],
      combineDateAndTime(theListing['startTime'], fairDate),
      combineDateAndTime(theListing['endTime'], fairDate),
      noticePeriod,
      isScheduled,
      null
    );
    alertSchedules.add(newAlert);
    return nextId++;
  }

  void removeAlertByListingId(String listingId) {
    debugPrint('AlertScheduleStore removeAlertById removing alert with listingId=$listingId');
    alertSchedules.removeWhere((a) => a.listingId == listingId);
  }

  void removeAlertById(int theId) {
    debugPrint('AlertScheduleStore removeAlertById removing alert with theId=$theId');
    alertSchedules.removeWhere((a) => a.id == theId);
  }

  bool updateAlertById(int theId, int? newTimeOffset) {
    final theAlert = alertSchedules.firstWhereOrNull((a) => a.id == theId);
    debugPrint('AlertScheduleStore updateAlertById looking for id=$theId in list of length ${alertSchedules.length} came up with $theAlert');
    if (theAlert != null) {
      if (newTimeOffset == null) { // we're just setting alert for start time
        theAlert.noticePeriod = 0;
      } else { // may not be quite right, but doesn't matter atm
        theAlert.noticePeriod = max(0, theAlert.noticePeriod - newTimeOffset);
      }
      return true;
    } else {
      return false;
    }
    
  }

  void removePastEventAlerts() {
    debugPrint('AlertScheduleStore removePastEventAlerts called');
    final now = DateTime.now();
    alertSchedules.removeWhere((a) => a.listingStartTime.subtract(Duration(minutes: a.noticePeriod)).isBefore(now));//todo test vs +1
  }

  void saveAllEventAlerts() async {
    debugPrint('AlertScheduleStore saveAllEventAlerts called');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alertsStore', jsonEncode(alertsStore));
  }

  void loadEventAlerts() async {
    debugPrint('AlertScheduleStore loadEventAlerts called');
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('alertsStore');
    if (jsonString != null) {
      alertsStore = AlertScheduleStore.fromJson(jsonDecode(jsonString));
    }
  }

}


AlertSchedule _$AlertScheduleFromJson(Map<String, dynamic> json) =>
    AlertSchedule(
      (json['id'] as num).toInt(),
      json['listingId'] as String,
      json['listingTitle'] as String,
      json['listingLocation'] as String,
      DateTime.parse(json['listingStartTime'] as String),
      DateTime.parse(json['listingEndTime'] as String),
      (json['noticePeriod'] as num).toInt(),
      json['isScheduled'] as bool,
      json['fromHighlight'] as bool?,
    );

Map<String, dynamic> _$AlertScheduleToJson(AlertSchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'listingId': instance.listingId,
      'listingTitle': instance.listingTitle,
      'listingLocation': instance.listingLocation,
      'listingStartTime': instance.listingStartTime.toIso8601String(),
      'listingEndTime': instance.listingEndTime.toIso8601String(),
      'noticePeriod': instance.noticePeriod,
      'isScheduled': instance.isScheduled,
      'fromHighlight': instance.fromHighlight,
    };

AlertScheduleStore _$AlertScheduleStoreFromJson(Map<String, dynamic> json) =>
    AlertScheduleStore(
      (json['alertSchedules'] as List<dynamic>)
          .map((e) => AlertSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['nextId'] as num).toInt(),
    );

Map<String, dynamic> _$AlertScheduleStoreToJson(AlertScheduleStore instance) =>
    <String, dynamic>{
      'alertSchedules': instance.alertSchedules,
      'nextId': instance.nextId,
    };

