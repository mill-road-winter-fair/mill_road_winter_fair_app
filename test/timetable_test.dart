import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

void main() {
  group('TimetablePage', () {
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
