// Dart SDK imports
import 'dart:convert';

// App imports
import 'package:mill_road_winter_fair_app/category_tools.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

// Third-party imports
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Test helpers, fakes and mocks
import 'mocks/listings_mocks.dart';
import 'pump_with_clock.dart';

const expectedSubcategories = {
  'food': 'Food & drink',
  'shopping': 'Shopping',
  'charityCommunityInfo': 'Charity, community, info',
  'performanceMusic': 'Music',
  'performanceChildrens': 'Children’s entertainment',
  'performanceDance': 'Dance',
  'performanceOther': 'Other performances',
  'visitExperience': 'Visits & experiences',
  'service': 'Services',
  'business': 'Other businesses',
};

String categoryListingId(String category) =>
    (26020 + expectedSubcategories.keys.toList().indexOf(category)).toString();

void main() {
  setUp(() async {
    onTest = true;
    await loadSettings();
    preferredSortingMethod = SortingMethod.alphabetical;
    locationServicesEnabled = false;
    locationPermission = LocationPermission.denied;
    currentLatLng = null;
    listings = [];
    favouriteListingKeys.value = {};
  });

  tearDown(() {
    listings = [];
    favouriteListingKeys.value = {};
  });

  test('API preserves each subcategory and the columns following business', () async {
    final expected = expectedSubcategories.keys
        .map((key) => listingFor(categoryListingId(key), key)).toList();
    final client = MockClient((_) async => http.Response(
      jsonEncode(mockListingsResponse(expected)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ));
    addTearDown(client.close);

    expect(await fetchListings(client), expected);
  });

  for (final entry in expectedSubcategories.entries) {
    test('${entry.key} is recognised as a single category', () {
      final listing = listingFor(categoryListingId(entry.key), entry.key);
      expect(countCategories(listing), entry.key.startsWith('performance')
          ? (1, 1)
          : (1, 0));
      expect(getCategory(listing), {
              'food': 'Food', 'shopping': 'Shopping',
              'charityCommunityInfo': 'Charity/Community/Info',
              'performanceMusic': 'Music',
              'performanceChildrens': 'Childrens',
              'performanceDance': 'Dance',
              'performanceOther': 'Other',
              'visitExperience': 'Visit/Experience',
              'service': 'Service', 
              'business': 'Business',
            }[entry.key]);
    });

    for (final page in ['all', 'favourite']) {
      testWidgets('$page menu filters ${entry.key} independently', (tester) async {
        listings = [
          for (final key in expectedSubcategories.keys) listingFor(categoryListingId(key), key),
          listingFor('26030', entry.key),
          {...listingFor('26104', entry.key), 'groupParent': 'TRUE'},
        ];
        favouriteListingKeys.value = {...expectedSubcategories.keys.map(categoryListingId), '26104'};
        String? selected;
        await tester.pumpWithClock(MaterialApp(home: Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            return FilteredListingsPage(
              filterCategory: page,
              subfilterCategory: selected,
              listings: listings,
              onTabSelected: (_) {},
              onSubfilterChange: (value) => setState(() => selected = value),
              analyticsService: FakeAnalyticsService(),
            );
          }),
        )));
        await tester.pumpAndSettle();

        final menuFinder = find.byKey(const ValueKey('filterdropdown'));
        final menuButtonFinder = find.descendant(
          of: menuFinder,
          matching: find.byType(IconButton),
        );
        await tester.tap(menuButtonFinder);
        await tester.pumpAndSettle();

        expect(find.text('Show'), findsOneWidget);
        expect(find.text('Everything'), findsOneWidget);
        for (final label in expectedSubcategories.values) {
          expect(find.text(label), findsOneWidget);
        }

        final selectedOption = find.text(expectedSubcategories[entry.key]!);
        await tester.ensureVisible(selectedOption);
        await tester.tap(selectedOption);
        await tester.pumpAndSettle();

        final state = tester.state<FilteredListingsPageState>(find.byType(FilteredListingsPage));
        expect(state.filteredListings.map((listing) => listing['id']),
            unorderedEquals([categoryListingId(entry.key), if (page == 'all') '26030']));
        expect(state.isShowingJustPerformance, entry.key.startsWith('performance'));

        await tester.tap(menuButtonFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Everything'));
        await tester.pumpAndSettle();
        expect(state.filteredListings.length, expectedSubcategories.length + (page == 'all' ? 1 : 0));
      });
    }
  }

  test('business combined with another subcategory is mixed', () {
    final listing = {...listingFor('26031', 'business'), 'shopping': 'TRUE'};
    expect(countCategories(listing), (2, 0));
    expect(getCategory(listing), 'Mixed');
  });
}
