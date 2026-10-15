import 'mocks/listings_mocks.dart';
import 'pump_with_clock.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mill_road_winter_fair_app/category_tools.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/firebase_analytics.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

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
      testWidgets('$page dropdown filters ${entry.key} independently', (tester) async {
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

        final dropdownFinder = find.descendant(
          of: find.byKey(const ValueKey('filteringdropdown')),
          matching: find.byType(DropdownMenu<String?>),
        );
        final dropdown = tester.widget<DropdownMenu<String?>>(dropdownFinder);
        expect({for (final option in dropdown.dropdownMenuEntries)
          option.value: option.label}, {null: 'Everything', ...expectedSubcategories});
        dropdown.onSelected!(entry.key);
        await tester.pumpAndSettle();

        final state = tester.state<FilteredListingsPageState>(find.byType(FilteredListingsPage));
        expect(state.filteredListings.map((listing) => listing['id']),
            unorderedEquals([categoryListingId(entry.key), if (page == 'all') '26030']));
        expect(state.isShowingJustPerformance, entry.key.startsWith('performance'));

        tester.widget<DropdownMenu<String?>>(dropdownFinder).onSelected!(null);
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
