import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/in_app_notifications.dart';

const headers = ['id', 'title', 'body', 'starts_at', 'expires_at', 'enabled'];
String payload(List<List<Object>> rows) => jsonEncode({
      'values': [headers, ...rows],
    });
List<Object> row(
  String id, {
  String start = '2026-10-29T10:00:00Z',
  String end = '2026-10-29T18:00:00Z',
  Object enabled = true,
}) =>
    [id, 'Fair update', 'Some information', start, end, enabled];

void main() {
  test('validates dates, enabled flags, missing cells and duplicate IDs', () {
    final parsed = FairNotification.parse(
      payload([
        row('valid'),
        row('disabled', enabled: false),
        row('ambiguous', start: '2026-10-29T10:00:00'),
        row('reversed', end: '2026-10-29T09:00:00Z'),
        row('duplicate'),
        row('duplicate'),
        ['short'],
      ]),
    );
    expect(parsed.map((n) => n.id), ['valid']);
    expect(
      () => FairNotification.parse('{"values":[["title"]]}'),
      throwsFormatException,
    );
  });

  test('excludes future, expired and over-24-hour-old notifications', () {
    final now = DateTime.parse('2026-10-29T12:00:00Z');
    final parsed = FairNotification.parse(
      payload([
        row('valid'),
        row('future', start: '2026-10-29T13:00:00Z'),
        row('expired', end: '2026-10-29T12:00:00Z'),
        row('old', start: '2026-10-28T12:00:00Z'),
      ]),
    );
    expect(parsed.where((n) => n.isCurrent(now)).map((n) => n.id), ['valid']);
  });

  testWidgets('polls only in foreground, throttles resumes, persists seen IDs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime.parse('2026-10-29T12:00:00Z');
    var requests = 0;
    FairNotificationService create() => FairNotificationService(
          endpoint: 'https://example.com/notifications',
          apiKey: 'test-key',
          preferences: prefs,
          now: () => now,
          client: MockClient((request) async {
            requests++;
            expect(request.headers['x-api-key'], 'test-key');
            return http.Response(payload([row('one')]), 200);
          }),
        );
    var service = create();
    await service.poll();
    expect(requests, 0);
    await service.setActive(true);
    await tester.pump();
    expect(service.current?.id, 'one');
    await service.setActive(false);
    await service.setActive(true);
    await tester.pump();
    expect(requests, 1);
    service.dispose();
    now = now.add(const Duration(minutes: 6));
    service = create();
    await service.setActive(true);
    await tester.pump();
    expect(requests, 2);
    expect(service.current, isNull);
    service.dispose();
  });

  testWidgets('failed requests back off and never present cached content', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime.parse('2026-10-29T12:00:00Z');
    var requests = 0;
    final service = FairNotificationService(
      endpoint: 'https://example.com/notifications',
      apiKey: 'test-key',
      preferences: await SharedPreferences.getInstance(),
      now: () => now,
      client: MockClient((_) async {
        requests++;
        return http.Response('', 503);
      }),
    );
    await service.setActive(true);
    await tester.pump();
    now = now.add(const Duration(minutes: 6));
    await service.poll();
    expect(requests, 1);
    now = now.add(const Duration(minutes: 5));
    await service.poll();
    expect(requests, 2);
    expect(service.current, isNull);
    service.dispose();
  });

  testWidgets('banner can be dismissed and expires while visible', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = FairNotificationService(
      endpoint: 'https://example.com/notifications',
      apiKey: 'test-key',
      preferences: await SharedPreferences.getInstance(),
      now: () => DateTime.parse('2026-10-29T12:00:00Z'),
      client: MockClient(
        (_) async => http.Response(
          payload([
            row('one', end: '2026-10-29T12:00:10Z'),
          ]),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => FairNotificationHost(service: service, child: child!),
        home: const Scaffold(),
      ),
    );
    await tester.pump();
    expect(find.text('Fair update'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    await tester.pump(const Duration(seconds: 11));
    expect(find.text('Fair update'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
