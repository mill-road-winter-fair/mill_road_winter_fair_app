// Shared fictional listings. Use [mockListing] to get a mutable copy.
// Empty groupID means a standalone listing, rather than a missing value.
const listingHeaders = <String>[
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
  'endTime'
];

const _completeListing = <String, dynamic>{
  'id': '1',
  'visibleOnMap': 'TRUE',
  'cancelled': 'FALSE',
  'groupParent': 'FALSE',
  'brickAndMortar': 'FALSE',
  'emoji': '🍩',
  'title': 'Glazed and Confused',
  'subtitle': 'Doughnuts',
  'groupID': '',
  'food': 'TRUE',
  'shopping': 'FALSE',
  'charityCommunityInfo': 'FALSE',
  'performanceMusic': 'FALSE',
  'performanceChildrens': 'FALSE',
  'performanceDance': 'FALSE',
  'performanceOther': 'FALSE',
  'visitExperience': 'FALSE',
  'service': 'FALSE',
  'business': 'FALSE',
  'location': 'Gwydir Street',
  'description': 'Nice buns',
  'email': 'sales@glazedandconfused.example',
  'website': 'https://glazedandconfused.example',
  'phone': '01223 111111',
  'latLng': '52.199687,0.138813',
  'imageURL': 'https://glazedandconfused.example/doughnuts.jpg',
  'startTime': '10:30',
  'endTime': '16:30',
};

// Named scenarios keep test selection independent of array order.
final _listingScenarios = <String, Map<String, dynamic>>{
  'glazedAndConfused': {
    ..._completeListing,
  },
  'listing': {
    ..._completeListing,
    'title': 'Listing',
    'location': 'Mill Road',
  },
  'sushiSquad': {
    ..._completeListing,
    'id': '2',
    'emoji': '🍣',
    'title': 'Sushi Squad',
    'subtitle': 'Sushi',
    'location': 'Mortimer Road',
    'description': 'Cold rice',
    'website': 'https://sushisquad.example',
    'email': 'hello@sushisquad.example',
    'imageURL': 'https://sushisquad.example/sushi.jpg',
    'latLng': '52.200063,0.139313',
    'startTime': '12:00',
  },
  'biteClub': {
    ..._completeListing,
    'id': '3',
    'emoji': '🍔',
    'title': 'Bite Club',
    'subtitle': 'Burgers',
    'location': 'East Road',
    'description': 'Burgers worth breaking the first rule for.',
    'website': 'https://biteclub.example',
    'email': 'hello@biteclub.example',
    'imageURL': 'https://biteclub.example/burgers.jpg',
    'phone': '01223 333333',
    'latLng': '52.202313,0.131562',
    'startTime': '14:00',
  },
  'musicalDoughnuts': {
    ..._completeListing,
    'performanceMusic': 'TRUE',
  },
  'sushiFirstId': {
    ..._completeListing,
    'emoji': '🍣',
    'title': 'Sushi Squad',
    'subtitle': 'Sushi',
    'location': 'Mortimer Road',
    'description': 'Cold rice',
    'website': 'https://sushisquad.example',
    'email': 'hello@sushisquad.example',
    'imageURL': 'https://sushisquad.example/sushi.jpg',
    'latLng': '52.200063,0.139313',
    'startTime': '12:00',
  },
  'doughnutsSecondId': {
    ..._completeListing,
    'id': '2',
  },
  'cachedListing': {
    ..._completeListing,
    'title': 'Cached listing',
  },
  'alertDoughnuts': {
    ..._completeListing,
    'id': 'listing-1',
  },
  'acousticStage': {
    ..._completeListing,
    'id': 'listing-2',
    'title': 'Acoustic Stage',
    'emoji': '🎸',
    'subtitle': 'Unplugged and slightly out of tune',
    'description': 'Local musicians with strings attached.',
    'food': 'FALSE',
    'performanceMusic': 'TRUE',
    'location': 'Mill Road',
    'startTime': '12:00',
    'endTime': '14:00',
  },
  'foodGroup': {
    ..._completeListing,
    'groupParent': 'TRUE',
    'title': 'Food Group',
    'subtitle': 'Food',
    'groupID': '1',
    'location': 'Headly Street',
    'latLng': '52.199838,0.139016',
  },
  'groupedDoughnuts': {
    ..._completeListing,
    'id': '2',
    'visibleOnMap': 'FALSE',
    'groupID': '1',
    'location': 'Headly Street',
    'startTime': '11:00',
    'endTime': '15:00',
  },
  'nearbySushi': {
    ..._completeListing,
    'id': '3',
    'emoji': '🍣',
    'title': 'Sushi Squad',
    'subtitle': 'Sushi',
    'location': 'Mortimer Road',
    'description': 'Cold rice',
    'website': 'https://sushisquad.example',
    'email': 'hello@sushisquad.example',
    'imageURL': 'https://sushisquad.example/sushi.jpg',
    'phone': '01223 222222',
    'latLng': '52.199188,0.139437',
    'startTime': '12:00',
  },
  'seafoodGroup': {
    ..._completeListing,
    'id': 'sea-group',
    'groupParent': 'TRUE',
    'title': 'Seafood Group',
    'subtitle': 'Food',
    'groupID': 'sea-group',
    'location': 'Devonshire Road',
    'latLng': '52.199838,0.139016',
  },
  'seabreezeStall': {
    ..._completeListing,
    'id': 'sea-specific',
    'title': 'Seabreeze Stall',
    'subtitle': 'Food',
    'groupID': 'sea-group',
    'location': 'Devonshire Road',
    'latLng': '52.199838,0.139016',
  },
  'informationPoint': {
    ..._completeListing,
    'id': '4',
    'title': 'Information Point',
    'food': 'FALSE',
    'service': 'TRUE',
    'subtitle': 'Directions and questionable local wisdom',
  },
  'cancelledDoughnuts': {
    ..._completeListing,
    'cancelled': 'TRUE',
    'subtitle': 'Food • Doughnuts',
  },
  'doughnutInfoSheet': {
    ..._completeListing,
    'subtitle': 'Food • Doughnuts',
  },
  'performanceGroup': {
    ..._completeListing,
    'id': 'performances',
    'title': 'Performances',
    'subtitle': 'Music',
    'groupID': 'performances',
    'groupParent': 'TRUE',
    'food': 'FALSE',
    'performanceMusic': 'TRUE',
    'location': 'St Barnabas Road',
  },
  'permanentShop': {
    ..._completeListing,
    'title': 'Mill Road Shop',
    'subtitle': 'Shopping',
    'location': 'Mill Road',
    'food': 'FALSE',
    'shopping': 'TRUE',
    'brickAndMortar': 'TRUE',
  },
  'analyticsActions': {
    ..._completeListing,
    'id': 'listing-456',
    'title': 'Another listing',
    'location': 'Tenison Road',
    'description': 'Details',
    'email': 'test@example.com',
    'website': 'https://example.com',
  },
};

// The complete catalogue. Scenario variants may deliberately reuse IDs;
// select a coherent subset when displaying several listings together.
final List<Map<String, dynamic>> listingsMocks = List.unmodifiable([
  ..._listingScenarios.values.map(Map<String, dynamic>.unmodifiable),
  ...categoryListingsMocks,
  Map<String, dynamic>.unmodifiable(_longDescriptionListing),
]);

final _longDescriptionListing = {
  ..._completeListing,
  'id': 'scrollable',
  'title': 'The Neverending Storey',
  'subtitle': 'Stall',
  'location': 'Mill Road',
  'description': List.filled(150, 'Long details.').join(' '),
  'startTime': '10:00',
  'endTime': '23:59',
};

// Each subcategory has exactly one flag enabled.
final List<Map<String, dynamic>> categoryListingsMocks = List.unmodifiable([
  for (final (category, title, location) in [
    ('food', 'Wok This Way', 'Mill Road'),
    ('shopping', 'Knit Happens', 'Mortimer Road'),
    ('charityCommunityInfo', 'Good Deeds and Biscuits', 'Headly Street'),
    ('performanceMusic', 'The Treble Makers', 'Tenison Road'),
    ('performanceChildrens', 'Tiny Tophat Theatre', 'St Barnabas Road'),
    ('performanceDance', 'Two Left Feet', 'Devonshire Road'),
    ('performanceOther', 'Mildly Amazing Magic', 'Gwydir Street'),
    ('visitExperience', 'The Curious Cupboard', 'Cavendish Road'),
    ('service', 'The Helpful Hedgehog', 'Catharine Street'),
    ('business', 'Pencil Pushers United', 'Coleridge Road'),
  ])
    Map<String, dynamic>.unmodifiable({
      ..._completeListing,
      'id': category,
      'food': 'FALSE',
      category: 'TRUE',
      'title': title,
      'subtitle': 'Winter fair merriment',
      'location': location,
      'description': 'Visit $title for a little festive nonsense.',
      'email': 'hello@$category.example',
      'website': 'https://$category.example',
      'imageURL': 'https://$category.example/stall.jpg',
    }),
]);

// Always return a fresh map: tests routinely change flags, times and IDs.
Map<String, dynamic> mockListing(String scenario) {
  final listing = scenario == 'longDescription'
      ? _longDescriptionListing
      : _listingScenarios[scenario];
  if (listing == null) throw ArgumentError.value(scenario, 'scenario');
  return Map<String, dynamic>.from(listing);
}

Map<String, dynamic> listingFor(String id, String subcategory) => {
      ...categoryListingsMocks
          .singleWhere((listing) => listing['id'] == subcategory),
      'id': id,
    };

// Encode the same fixtures in the spreadsheet API's column order.
Map<String, dynamic> mockListingsResponse(
        List<Map<String, dynamic>> listings) =>
    {
      'values': <List<dynamic>>[
        List<dynamic>.from(listingHeaders),
        for (final listing in listings)
          [for (final header in listingHeaders) listing[header]],
      ],
    };
