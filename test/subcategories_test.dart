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

// API column order from the supplied 28-column response.
const apiHeaders = [
  'id',
  'visibleOnMap',
  'cancelled',
  'groupParent',
  'brickAndMortar',
  'emoji',
  'title',
  'subtitle',
  'groupID',
  'food',
  'shopping',
  'charityCommunityInfo',
  'performanceMusic',
  'performanceChildrens',
  'performanceDance',
  'performanceOther',
  'visitExperience',
  'service',
  'business',
  'location',
  'description',
  'email',
  'website',
  'phone',
  'latLng',
  'imageURL',
  'startTime',
  'endTime',
];

const expectedSubcategories = {
  'food': 'Food & Drink',
  'shopping': 'Shopping & Stalls',
  'charityCommunityInfo': 'Charity, Community, Info',
  'performanceMusic': 'Music',
  'performanceChildrens': 'Children’s',
  'performanceDance': 'Dance',
  'performanceOther': 'Other performances',
  'visitExperience': 'Visit & Experience',
  'service': 'Services',
  'business': 'Business',
};

Map<String, dynamic> listingFor(String id, String subcategory) => {
  for (final header in apiHeaders) header: '',
  for (final key in expectedSubcategories.keys) key: 'FALSE',
  'id': id,
  'title': id,
  'visibleOnMap': 'TRUE',
  'cancelled': 'FALSE',
  'groupParent': 'FALSE',
  'brickAndMortar': 'FALSE',
  subcategory: 'TRUE',
  'location': 'Mill Road',
  'latLng': '52.199687,0.138813',
  'startTime': '10:30',
  'endTime': '16:30',
};

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

  test(
    'API preserves each subcategory and the columns following business',
    () async {
      final expected =
          expectedSubcategories.keys
              .map((key) => listingFor(key, key))
              .toList();
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'range': "'2025'!A1:AB350",
            'majorDimension': 'ROWS',
            'values': [
              apiHeaders,
              for (final listing in expected)
                [for (final header in apiHeaders) listing[header]],
            ],
          }),
          200,
        ),
      );
      addTearDown(client.close);

      expect(await fetchListings(client), expected);
    },
  );

  for (final entry in expectedSubcategories.entries) {
    test('${entry.key} is recognised as a single category', () {
      final listing = listingFor('single', entry.key);
      expect(countCategories(listing), 1);
      expect(
        getCategory(listing),
        entry.key.startsWith('performance')
            ? 'Performance'
            : {
              'food': 'Food',
              'shopping': 'Shopping',
              'charityCommunityInfo': 'Charity/Community/Info',
              'visitExperience': 'Visit/Experience',
              'service': 'Service',
              'business': 'Business',
            }[entry.key],
      );
    });

    for (final page in ['all', 'favourite']) {
      testWidgets('$page dropdown filters ${entry.key} independently', (
        tester,
      ) async {
        listings = [
          for (final key in expectedSubcategories.keys) listingFor(key, key),
          listingFor('not-favourited', entry.key),
          {...listingFor('parent', entry.key), 'groupParent': 'TRUE'},
        ];
        favouriteListingKeys.value = {...expectedSubcategories.keys, 'parent'};
        String? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return FilteredListingsPage(
                    filterCategory: page,
                    subfilterCategory: selected,
                    listings: listings,
                    onTabSelected: (_) {},
                    onSubfilterChange:
                        (value) => setState(() => selected = value),
                    analyticsService: FakeAnalyticsService(),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final dropdownFinder = find.descendant(
          of: find.byKey(const ValueKey('filteringdropdown')),
          matching: find.byType(DropdownMenu<String?>),
        );
        final dropdown = tester.widget<DropdownMenu<String?>>(dropdownFinder);
        expect(
          {
            for (final option in dropdown.dropdownMenuEntries)
              option.value: option.label,
          },
          {null: 'All', ...expectedSubcategories},
        );
        dropdown.onSelected!(entry.key);
        await tester.pumpAndSettle();

        final state = tester.state<FilteredListingsPageState>(
          find.byType(FilteredListingsPage),
        );
        expect(
          state.filteredListings.map((listing) => listing['id']),
          unorderedEquals([entry.key, if (page == 'all') 'not-favourited']),
        );
        expect(
          state.isShowingJustPerformance,
          entry.key.startsWith('performance'),
        );

        tester.widget<DropdownMenu<String?>>(dropdownFinder).onSelected!(null);
        await tester.pumpAndSettle();
        expect(
          state.filteredListings.length,
          expectedSubcategories.length + (page == 'all' ? 1 : 0),
        );
      });
    }
  }

  test('business combined with another subcategory is mixed', () {
    final listing = {...listingFor('mixed', 'business'), 'shopping': 'TRUE'};
    expect(countCategories(listing), 2);
    expect(getCategory(listing), 'Mixed');
  });
}
