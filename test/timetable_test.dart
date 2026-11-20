// App imports
import 'package:mill_road_winter_fair_app/dependencies/date_time_provider.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/timetable_page.dart';

// Third-party imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Test helpers, fakes and mocks
import 'mocks/listings_mocks.dart';
import 'pump_with_clock.dart';

class MutableClock implements DateTimeProvider {
  DateTime time;
  MutableClock(this.time);
  @override
  DateTime now() => time;
}

void main() {
  group('TimetablePage', () {
    for (final initiallyEmpty in [false, true]) {
      for (final resume in [false, true]) {
        testWidgets('now or soon refreshes on ${resume ? 'resume' : 'tick'} (initially empty: $initiallyEmpty)', (tester) async {
          onTest = true;
          firstExecution = false;
          SharedPreferences.setMockInitialValues({});
          final savedListings = listings;
          addTearDown(() => listings = savedListings);
          listings = [
            if (!initiallyEmpty) mockListing('morningPerformance'),
            mockListing('noonPerformance'),
          ];
          final clock = MutableClock(DateTime(fairDate.year, fairDate.month, fairDate.day, 10));
          await tester.pumpWithClock(MaterialApp(home: TimetablePage(
            theEvents: listings,
            onlyNowOrSoon: true,
            onTabSelected: (_) {},
            onFilterChange: (_, __) {},
            analyticsService: FakeAnalyticsService(),
          )), dateTimeProvider: clock);
          await tester.pumpAndSettle();
          final state = tester.state<TimetablePageState>(find.byType(TimetablePage));
          List<String> selectedIds() => state.theFilteredEvents.values.expand((events) => events).map((event) => event.id).toList();
          expect(selectedIds(), initiallyEmpty ? isEmpty : ['morning']);

          clock.time = DateTime(fairDate.year, fairDate.month, fairDate.day, 11, 45);
          if (resume) {
            state.didChangeAppLifecycleState(AppLifecycleState.resumed);
            await tester.pump();
          } else {
            await tester.pump(const Duration(seconds: 31));
          }
          expect(selectedIds(), ['noon']);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }

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
