import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/main_alerting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _FakeAndroidFlutterLocalNotificationsPlugin
    extends AndroidFlutterLocalNotificationsPlugin {
  final List<int> cancelledIds = <int>[];
  final List<Map<String, dynamic>> scheduled = <Map<String, dynamic>>[];
  bool notificationsEnabled = true;
  bool exactAlarmsGranted = true;
  DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse;

  @override
  Future<bool> initialize({
    required AndroidInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    this.onDidReceiveNotificationResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async =>
      NotificationAppLaunchDetails(false);

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    AndroidNotificationDetails? notificationDetails,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exact,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'scheduledDate': scheduledDate,
      'scheduleMode': scheduleMode,
    });
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelledIds.add(id);
  }

  @override
  Future<bool?> requestExactAlarmsPermission() async => exactAlarmsGranted;

  @override
  Future<bool?> requestNotificationsPermission() async => notificationsEnabled;

  @override
  Future<bool?> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async => <PendingNotificationRequest>[];
}

Future<void> _withAndroidPlatform(Future<void> Function() callback) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  try {
    await callback();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  setUp(() async {
    tzdata.initializeTimeZones();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (call) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => true,
    );
    FlutterLocalNotificationsPlatform.instance =
        _FakeAndroidFlutterLocalNotificationsPlugin();
    SharedPreferences.setMockInitialValues({});
    listings = [
      {
        'id': 'listing-1',
        'title': 'Glazed and Confused',
        'location': 'Gwydir St Car Park',
        'startTime': '10:30',
        'endTime': '16:30',
      },
      {
        'id': 'listing-2',
        'title': 'Acoustic Stage',
        'location': 'Mill Road',
        'startTime': '12:00',
        'endTime': '14:00',
      },
    ];
    alertsStore = AlertScheduleStore.initial();
    settingsOpened = false;
    alertsPermissionGranted = false;
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  });

  group('main_alerting.dart', () {
    test('initialiseFlutterLocalNotificationsPlugin initializes without a launch response', () async {
      await _withAndroidPlatform(initialiseFlutterLocalNotificationsPlugin);
    });

    test('initialiseFlutterLocalNotificationsPlugin forwards notification responses to the stream', () async {
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 42,
      );
      final streamedResponse = notificationStream.stream.first;

      await _withAndroidPlatform(initialiseFlutterLocalNotificationsPlugin);
      (FlutterLocalNotificationsPlatform.instance as _FakeAndroidFlutterLocalNotificationsPlugin)
          .onDidReceiveNotificationResponse!(response);

      expect(await streamedResponse, same(response));
    });

    test('calculateAlertActionCategories returns the correct action set for each window', () {
      final zero = calculateAlertActionCategories(0);
      expect(zero.$1, 'UnderwayCategory');
      expect(zero.$2, isEmpty);

      final five = calculateAlertActionCategories(5);
      expect(five.$1, '5MinsCategory');
      expect(five.$2.map((action) => action.id), contains('snoozeStart'));

      final fifteen = calculateAlertActionCategories(15);
      expect(fifteen.$1, '15MinsCategory');
      expect(fifteen.$2.map((action) => action.id), containsAll(['snooze5mins', 'snoozeStart']));

      final thirty = calculateAlertActionCategories(30);
      expect(thirty.$1, '30MinsCategory');
      expect(thirty.$2.map((action) => action.id), containsAll(['snooze10mins', 'snooze20mins', 'snoozeStart']));

      final sixty = calculateAlertActionCategories(60);
      expect(sixty.$1, '60MinsCategory');
      expect(sixty.$2.map((action) => action.id), containsAll(['snooze15mins', 'snooze30mins', 'snoozeStart']));
    });

    test('notificationTapBackground handles a snooze action without throwing', () async {
      await _withAndroidPlatform(() async {
        final startTime = DateTime.now().add(const Duration(minutes: 30));
        final endTime = startTime.add(const Duration(minutes: 90));
        final payload = jsonEncode({
          'listingId': 'listing-1',
          'listingTitle': 'Glazed and Confused',
          'listingLocation': 'Gwydir St Car Park',
          'listingStartTime': startTime.toIso8601String(),
          'listingEndTime': endTime.toIso8601String(),
        });

        notificationTapBackground(
          NotificationResponse(
            notificationResponseType: NotificationResponseType.selectedNotificationAction,
            id: 99,
            actionId: 'snoozeStart',
            payload: payload,
          ),
        );
        await Future<void>.delayed(Duration.zero);
      });
    });

    test('notificationTapBackground ignores invalid payloads and unsupported actions', () async {
      final validStart = DateTime.now().add(const Duration(hours: 1));
      final validEnd = validStart.add(const Duration(hours: 1));
      final invalidStartPayload = jsonEncode({
        'listingId': 'listing-1',
        'listingTitle': 'Glazed and Confused',
        'listingLocation': 'Gwydir St Car Park',
        'listingStartTime': 'not-a-date',
        'listingEndTime': validEnd.toIso8601String(),
      });
      final validPayload = jsonEncode({
        'listingId': 'listing-1',
        'listingTitle': 'Glazed and Confused',
        'listingLocation': 'Gwydir St Car Park',
        'listingStartTime': validStart.toIso8601String(),
        'listingEndTime': validEnd.toIso8601String(),
      });

      notificationTapBackground(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: null,
        payload: validPayload,
      ));
      notificationTapBackground(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: null,
      ));
      notificationTapBackground(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: '{',
      ));
      notificationTapBackground(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: invalidStartPayload,
      ));
      notificationTapBackground(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        id: 1,
        actionId: 'unsupported-action',
        payload: validPayload,
      ));
      await Future<void>.delayed(Duration.zero);

      expect((FlutterLocalNotificationsPlatform.instance as _FakeAndroidFlutterLocalNotificationsPlugin).scheduled, isEmpty);
    });

    test('notificationTapBackground schedules each supported snooze action', () async {
      await _withAndroidPlatform(() async {
        final startTime = DateTime.now().add(const Duration(hours: 2));
        final endTime = startTime.add(const Duration(hours: 1));
        final payload = jsonEncode({
          'listingId': 'listing-1',
          'listingTitle': 'Glazed and Confused',
          'listingLocation': 'Gwydir St Car Park',
          'listingStartTime': startTime.toIso8601String(),
          'listingEndTime': endTime.toIso8601String(),
        });
        const actionIds = [
          'snooze5mins',
          'snooze10mins',
          'snooze15mins',
          'snooze20mins',
          'snooze30mins',
        ];

        for (var index = 0; index < actionIds.length; index++) {
          notificationTapBackground(NotificationResponse(
            notificationResponseType: NotificationResponseType.selectedNotificationAction,
            id: index + 1,
            actionId: actionIds[index],
            payload: payload,
          ));
          await Future<void>.delayed(Duration.zero);
        }

        expect((FlutterLocalNotificationsPlatform.instance as _FakeAndroidFlutterLocalNotificationsPlugin).scheduled, hasLength(actionIds.length));
      });
    });

    test('notificationTapBackground ignores an invalid end time after a snooze action', () async {
      await _withAndroidPlatform(() async {
        final startTime = DateTime.now().add(const Duration(hours: 1));
        final payload = jsonEncode({
          'listingId': 'listing-1',
          'listingTitle': 'Glazed and Confused',
          'listingLocation': 'Gwydir St Car Park',
          'listingStartTime': startTime.toIso8601String(),
          'listingEndTime': 'not-a-date',
        });

        notificationTapBackground(NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotificationAction,
          id: 1,
          actionId: 'snooze5mins',
          payload: payload,
        ));
        await Future<void>.delayed(Duration.zero);

        expect((FlutterLocalNotificationsPlatform.instance as _FakeAndroidFlutterLocalNotificationsPlugin).scheduled, isEmpty);
      });
    });

    test('requestAlertPermissions returns false on an unsupported host', () async {
      final result = await requestAlertPermissions();
      expect(result, isFalse);
    });

    test('updateAlertNoticePeriodById rewrites the persisted alert period', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = AlertScheduleStore([
        AlertSchedule(
          7,
          'listing-1',
          'Glazed and Confused',
          'Gwydir St Car Park',
          fairDate.add(const Duration(hours: 10)),
          fairDate.add(const Duration(hours: 11)),
          15,
          true,
          null,
        ),
      ], 8);
      await prefs.setString('alertsStore', jsonEncode(store));

      await updateAlertNoticePeriodById(7, 30);

      final savedJson = prefs.getString('alertsStore');
      expect(savedJson, isNotNull);
      final reloaded = AlertScheduleStore.fromJson(jsonDecode(savedJson!));
      expect(reloaded.alertSchedules.single.noticePeriod, 30);
    });

    test('updateAlertNoticePeriodById ignores missing persistence and unknown ids', () async {
      await updateAlertNoticePeriodById(999, 30);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alertsStore', jsonEncode(AlertScheduleStore.initial()));
      await updateAlertNoticePeriodById(999, 30);

      expect(AlertScheduleStore.fromJson(jsonDecode(prefs.getString('alertsStore')!)).alertSchedules, isEmpty);
    });

    test('AlertScheduleStore can add, find, and remove alerts and purge expired ones', () {
      final store = AlertScheduleStore.initial();
      final id = store.addAlert('listing-1', 15, true);

      expect(id, 0);
      expect(store[0].listingId, 'listing-1');
      expect(store.addAlert('missing-listing', 15, true), -1);
      expect(store.alertExists('listing-1'), isTrue);
      expect(store.alertIdForListing('listing-1'), 0);

      final placeholder = AlertSchedule(
        1,
        'listing-2',
        'Acoustic Stage',
        'Mill Road',
        DateTime.now().subtract(const Duration(minutes: 2)),
        DateTime.now().add(const Duration(minutes: 10)),
        5,
        true,
        null,
      );
      store.alertSchedules.add(placeholder);
      store.removeAlertByListingId('listing-2');
      expect(store.alertExists('listing-2'), isFalse);

      final stale = AlertSchedule(
        2,
        'listing-2',
        'Acoustic Stage',
        'Mill Road',
        DateTime.now().subtract(const Duration(minutes: 15)),
        DateTime.now().subtract(const Duration(minutes: 5)),
        10,
        true,
        null,
      );
      store.alertSchedules.add(stale);
      store.removePastEventAlerts();
      expect(store.alertSchedules.any((a) => a.id == 2), isFalse);

      store.removeAlertById(0);
      expect(store.alertSchedules, isEmpty);
    });

    test('AlertScheduleStoreJSON round-trips through SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final alert = AlertSchedule(
        12,
        'listing-2',
        'Acoustic Stage',
        'Mill Road',
        now,
        now.add(const Duration(minutes: 30)),
        25,
        true,
        true,
      );
      final store = AlertScheduleStore([alert], 13);

      await prefs.setString('alertsStore', jsonEncode(store));
      final jsonString = prefs.getString('alertsStore');
      expect(jsonString, isNotNull);

      final reloaded = AlertScheduleStore.fromJson(jsonDecode(jsonString!));
      expect(reloaded.alertSchedules.first.id, 12);
      expect(reloaded.alertSchedules.first.listingTitle, 'Acoustic Stage');
      expect(reloaded.alertSchedules.first.fromHighlight, isTrue);
    });

    test('saveAllEventAlerts and loadEventAlerts round-trip stored data', () async {
      final store = AlertScheduleStore([
        AlertSchedule(
          2,
          'listing-2',
          'Acoustic Stage',
          'Mill Road',
          fairDate.add(const Duration(hours: 12)),
          fairDate.add(const Duration(hours: 13)),
          20,
          true,
          null,
        ),
      ], 3);
      alertsStore = store;

      alertsStore.saveAllEventAlerts();
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('alertsStore'), isNotNull);

      alertsStore = AlertScheduleStore.initial();
      alertsStore.loadEventAlerts();
      await Future<void>.delayed(Duration.zero);
      expect(alertsStore.alertSchedules, isNotEmpty);
      expect(alertsStore.alertSchedules.single.listingId, 'listing-2');
    });

    test('loadEventAlerts and refreshEventAlertSchedules leave the store unchanged without saved data', () async {
      alertsStore = AlertScheduleStore.initial();

      alertsStore.loadEventAlerts();
      await alertsStore.refreshEventAlertSchedules();
      await Future<void>.delayed(Duration.zero);

      expect(alertsStore.alertSchedules, isEmpty);
      expect(alertsStore.nextId, 0);
    });

    test('refreshEventAlertSchedules reloads stored alerts while preserving current store', () async {
      final prefs = await SharedPreferences.getInstance();
      final live = AlertScheduleStore([
        AlertSchedule(
          18,
          'listing-1',
          'Glazed and Confused',
          'Gwydir St Car Park',
          fairDate.add(const Duration(hours: 10)),
          fairDate.add(const Duration(hours: 11)),
          15,
          true,
          null,
        ),
      ], 19);
      alertsStore = AlertScheduleStore([
        AlertSchedule(
          99,
          'stale',
          'Old',
          'Nowhere',
          fairDate.add(const Duration(hours: 8)),
          fairDate.add(const Duration(hours: 9)),
          5,
          false,
          null,
        ),
      ], 100);
      await prefs.setString('alertsStore', jsonEncode(live));

      await alertsStore.refreshEventAlertSchedules();

      expect(alertsStore.alertSchedules.single.id, 18);
      expect(alertsStore.alertSchedules.single.listingId, 'listing-1');
    });
  });

  group('helpers.dart alert UI helpers', () {
    testWidgets('showNoPermissionsDialog shows a permission request to the user', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showNoPermissionsDialog(context, Theme.of(context).colorScheme);
                },
                child: const Text('Open dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('need to give this app permission'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.textContaining('need to give this app permission'), findsNothing);
    });

    testWidgets('toggleListingAlert sets an alert when permission is already granted', (tester) async {
      await _withAndroidPlatform(() async {
        alertsPermissionGranted = true;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(),
            ),
          ),
        );

        await toggleListingAlert('listing-1', 15, tester.element(find.byType(SizedBox)));
        await tester.pump(const Duration(seconds: 3));

        expect(alertsStore.alertSchedules, isNotEmpty);
        expect(alertsStore.alertSchedules.first.listingId, 'listing-1');
      });
    });

    testWidgets('toggleListingAlert opens the permissions dialog when permission request fails', (tester) async {
      settingsOpened = false;
      alertsPermissionGranted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await toggleListingAlert('listing-1', 15, context);
                },
                child: const Text('Try alert'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Try alert'));
      await tester.pumpAndSettle();

      expect(find.textContaining('need to give this app permission'), findsOneWidget);
      expect(settingsOpened, isTrue);
    });

    testWidgets('toggleListingAlert retries permissions after returning from Settings', (tester) async {
      settingsOpened = true;
      alertsPermissionGranted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await toggleListingAlert('listing-1', 15, context);
                },
                child: const Text('Try again'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(settingsOpened, isTrue);
      expect(find.text('Open Settings'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.textContaining('need to give this app permission'), findsNothing);
    });

    testWidgets('setTheAlert cancels an existing scheduled alert for the listing', (tester) async {
      await _withAndroidPlatform(() async {
        final listingId = 'listing-1';
        alertsStore = AlertScheduleStore([
          AlertSchedule(
            66,
            listingId,
            'Glazed and Confused',
            'Gwydir St Car Park',
            fairDate.add(const Duration(hours: 10)),
            fairDate.add(const Duration(hours: 11)),
            15,
            true,
            null,
          ),
        ], 67);

        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
        await setTheAlert(tester.element(find.byType(SizedBox)), 15, listingId);
        await tester.pump(const Duration(seconds: 3));

        expect(alertsStore.alertSchedules, isEmpty);
        expect((FlutterLocalNotificationsPlatform.instance as _FakeAndroidFlutterLocalNotificationsPlugin).cancelledIds, contains(66));
      });
    });

    testWidgets('setTheAlert creates a new alert and persists it', (tester) async {
      await _withAndroidPlatform(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
        await setTheAlert(tester.element(find.byType(SizedBox)), 15, 'listing-1');
        await tester.pump(const Duration(seconds: 3));

        expect(alertsStore.alertSchedules, isNotEmpty);
        expect(alertsStore.alertSchedules.single.listingId, 'listing-1');
        expect(alertsStore.alertSchedules.single.noticePeriod, 15);
        expect((FlutterLocalNotificationsPlatform.instance as _FakeAndroidFlutterLocalNotificationsPlugin).scheduled, isNotEmpty);
      });
    });

    testWidgets('setTheAlert leaves alerts unchanged when the listing does not exist', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      await setTheAlert(tester.element(find.byType(SizedBox)), 15, 'missing-listing');
      await tester.pump();

      expect(alertsStore.alertSchedules, isEmpty);
      expect((FlutterLocalNotificationsPlatform.instance as _FakeAndroidFlutterLocalNotificationsPlugin).scheduled, isEmpty);
    });
  });
}
