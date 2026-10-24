import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/timetable_page.dart';

Map<String, dynamic> event(String id, Object? start, Object? end) => {
  'id': id,
  'title': id,
  'subtitle': '',
  'location': 'Stage',
  'performanceMusic': 'TRUE',
  'startTime': start,
  'endTime': end,
  'latLng': '52.2,0.14',
};

void main() {
  group('TimetablePage', () {
    test('skips irrelevant and invalid rows while preparing valid events', () {
      final dynamic state = TimetablePage(
        theEvents: const [],
        onTabSelected: (_) {},
        onFilterChange: (now, music) {},
        onlyNowOrSoon: false,
        analyticsService: FakeAnalyticsService(),
      ).createState();
      final invalidRows = [
        {'id': 'info', 'title': 'Information', 'service': 'TRUE'},
        event('information', '', '')..['performanceMusic'] = 'FALSE',
        event('blank', '', ''),
        event('missing', null, null),
        event('missing start', '', '12:00'),
        event('missing end', '11:00', ''),
        event('short', '11', '12:00'),
        event('text', 'unknown', '12:00'),
        event('number', 1100, '12:00'),
        event('hour', '24:00', '25:00'),
        event('minute', '11:60', '12:30'),
        event('reversed', '12:00', '11:00'),
        event('zero', '12:00', '12:00'),
        event('long', '10:00', '12:00'),
      ];
      expect(state.prepareEvents(invalidRows), isEmpty);
      final prepared = state.prepareEvents([
        ...invalidRows,
        event('later', '12:00', '12:30'),
        event('earlier', '9:00', '09:30'),
      ]);
      expect(prepared.keys, ['Stage']);
      expect(prepared['Stage'].map((e) => e.id), ['earlier', 'later']);
    });

    testWidgets('filter feedback replaces stale messages and expires', (tester) async {
      onTest = true;
      addTearDown(() => FToast().removeQueuedCustomToasts());

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) => FairScaffold(
          appBarTitle: 'Timetable',
          currentTab: 2,
          onTabSelected: (_) {},
          analyticsService: FakeAnalyticsService(),
          body: TextButton(
            onPressed: () => showInfoToast(context, 'Showing only music performances'),
            child: const Text('Change filter'),
          ),
        )),
      ));
      await tester.tap(find.text('Change filter'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Showing only music performances'), findsOneWidget);

      showInfoToast(tester.element(find.text('Change filter')), 'Showing everything');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('filter-toast')), findsOneWidget);
      expect(find.text('Showing only music performances'), findsNothing);
      expect(find.text('Showing everything'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('filter-toast')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
