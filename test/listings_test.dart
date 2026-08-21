import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings.dart';

@GenerateMocks([http.Client, SharedPreferences])
import 'listings_test.mocks.dart';

void main() {
  late MockClient mockClient;

  setUp(() async {
    mockClient = MockClient();
    dotenv.loadFromString(envString: '''
    HEROKU_API=MOCK_API
    HEROKU_API_KEY=MOCK_KEY
    ANDROID_GOOGLE_MAPS_SDK_API_KEY=MOCK_KEY
    ANDROID_GOOGLE_MAPS_DIRECTIONS_API_KEY=MOCK_KEY
    IOS_GOOGLE_MAPS_SDK_API_KEY=MOCK_KEY
    IOS_GOOGLE_MAPS_DIRECTIONS_API_KEY=MOCK_KEY
    SIGNING_KEY=MOCK_CERT
    IOS_BUNDLE_ID=com.theberridge.mill_road_winter_fair_app
    ''');
  });

  group('Listings', () {
    group('fetchListings', () {
      test('retries 10 times and returns empty listings when status code is not 200 and we have no listings cached', () async {
        final invalidResponse = {};

        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response.bytes(
            utf8.encode(jsonEncode(invalidResponse)),
            500,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );

        final result = await fetchExistingListings(mockClient);

        expect(result, []);
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(equals(10));
      });

      test('returns a list of listings when response is valid', () async {
        final mockResponse = {
          "values": [
            [
              "id",
              "visibleOnMap",
              "cancelled",
              "groupParent",
              "brickAndMortar",
              "emoji",
              "title",
              "subtitle",
              "groupID",
              "food",
              "shopping",
              "charityCommunityInfo",
              "performance",
              "visitExperience",
              "service",
              "location",
              "description",
              "email",
              "website",
              "phone",
              "latLng",
              "imageURL",
              "startTime",
              "endTime"
            ],
            [
              "1",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "🍩",
              "Glazed and Confused",
              "Doughnuts",
              "",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "Gwydir St Car Park",
              "Nice buns",
              "",
              "https://www.glazedandconfused.com",
              "01223 111111",
              "52.199687,0.138813",
              '',
              "10:30",
              "16:30",
            ]
          ]
        };

        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response.bytes(
            utf8.encode(jsonEncode(mockResponse)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );

        final result = await fetchListings(mockClient);

        expect(result.length, 1);
        expect(result, [
          {
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
            'performance': 'FALSE',
            'visitExperience': 'FALSE',
            'service': 'FALSE',
            'location': 'Gwydir St Car Park',
            'description': 'Nice buns',
            'email': '',
            'website': 'https://www.glazedandconfused.com',
            'phone': '01223 111111',
            'latLng': '52.199687,0.138813',
            'imageURL': '',
            'startTime': '10:30',
            'endTime': '16:30',
          }
        ]);
      });

      test('returns cached listings when status code is not 200', () async {
        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('Error', 500),
        );

        final result = await fetchExistingListings(mockClient);

        expect(result, [
          {
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
            'performance': 'FALSE',
            'visitExperience': 'FALSE',
            'service': 'FALSE',
            'location': 'Gwydir St Car Park',
            'description': 'Nice buns',
            'email': '',
            'website': 'https://www.glazedandconfused.com',
            'phone': '01223 111111',
            'latLng': '52.199687,0.138813',
            'imageURL': '',
            'startTime': '10:30',
            'endTime': '16:30',
          }
        ]);
      });
    });

    group('parseListings', () {
      late MockClient mockClient;

      setUp(() async {
        mockClient = MockClient();
        listings = [];
        dotenv.loadFromString(envString: '''
    HEROKU_API=MOCK_API
    HEROKU_API_KEY=MOCK_KEY
    ANDROID_GOOGLE_MAPS_SDK_API_KEY=MOCK_KEY
    ANDROID_GOOGLE_MAPS_DIRECTIONS_API_KEY=MOCK_KEY
    IOS_GOOGLE_MAPS_SDK_API_KEY=MOCK_KEY
    IOS_GOOGLE_MAPS_DIRECTIONS_API_KEY=MOCK_KEY
    SIGNING_KEY=MOCK_CERT
    IOS_BUNDLE_ID=com.theberridge.mill_road_winter_fair_app
    ''');
      });

      test('handles rows with missing cells by padding to headers', () async {
        final mockResponse = {
          "values": [
            [
              "id",
              "visibleOnMap",
              "cancelled",
              "groupParent",
              "brickAndMortar",
              "emoji",
              "title",
              "subtitle",
              "groupID",
              "food",
              "shopping",
              "charityCommunityInfo",
              "performance",
              "visitExperience",
              "service",
              "location",
              "description",
              "email",
              "website",
              "phone",
              "latLng",
              "imageURL",
              "startTime",
              "endTime"
            ],
            [
              "1",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "🍩",
              "Glazed and Confused",
              "Doughnuts",
              "",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "Gwydir St Car Park",
              "Nice buns",
              "",
              "https://www.glazedandconfused.com",
              "01223 111111",
              "52.199687,0.138813",
              "",
              "10:30",
              "", // endTime is blank (cleared cell)
            ]
          ]
        };

        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response.bytes(
            utf8.encode(jsonEncode(mockResponse)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );

        final result = await fetchListings(mockClient);

        expect(result.length, 1);
        expect(result.first['endTime'], '');
        expect(result.first['title'], 'Glazed and Confused');
        expect(result.first['id'], '1');
      });

      test('handles explicit null cells by converting them to empty strings', () async {
        final mockResponse = {
          "values": [
            [
              "id",
              "visibleOnMap",
              "cancelled",
              "groupParent",
              "brickAndMortar",
              "emoji",
              "title",
              "subtitle",
              "groupID",
              "food",
              "shopping",
              "charityCommunityInfo",
              "performance",
              "visitExperience",
              "service",
              "location",
              "description",
              "email",
              "website",
              "phone",
              "latLng",
              "imageURL",
              "startTime",
              "endTime"
            ],
            [
              "1",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "🍩",
              "Glazed and Confused",
              "Doughnuts",
              "",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "Gwydir St Car Park",
              "Nice buns",
              "",
              "https://www.glazedandconfused.com",
              "01223 111111",
              "52.199687,0.138813",
              "",
              "10:30",
              null,
            ]
          ]
        };

        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response.bytes(
            utf8.encode(jsonEncode(mockResponse)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );

        final result = await fetchListings(mockClient);

        expect(result.length, 1);
        expect(result.first['endTime'], '');
      });
    });

    group('fetchExistingListings', () {
      test('returns listings from fetchListings if no existing listings', () async {
        listings = [];

        final mockResponse = {
          "values": [
            [
              "id",
              "visibleOnMap",
              "cancelled",
              "groupParent",
              "brickAndMortar",
              "emoji",
              "title",
              "subtitle",
              "groupID",
              "food",
              "shopping",
              "charityCommunityInfo",
              "performance",
              "visitExperience",
              "service",
              "location",
              "description",
              "email",
              "website",
              "phone",
              "latLng",
              "imageURL",
              "startTime",
              "endTime"
            ],
            [
              "1",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "🍩",
              "Glazed and Confused",
              "Doughnuts",
              "",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "Gwydir St Car Park",
              "Nice buns",
              "",
              "https://www.glazedandconfused.com",
              "01223 111111",
              "52.199687,0.138813",
              "",
              "10:30",
              "16:30",
            ]
          ]
        };

        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response.bytes(
            utf8.encode(jsonEncode(mockResponse)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );

        final result = await fetchExistingListings(mockClient);

        expect(result.length, 1);
        expect(result.first["title"], "Glazed and Confused");
      });

      test('returns existing listings if already populated', () async {
        listings = [
          {
            'id': '1',
            'visibleOnMap': 'TRUE',
            'cancelled': 'FALSE',
            'brickAndMortar': 'FALSE',
            'emoji': '🍩',
            'title': 'Glazed and Confused',
            'subtitle': 'Doughnuts',
            'groupID': '',
            'food': 'TRUE',
            'shopping': 'FALSE',
            'charityCommunityInfo': 'FALSE',
            'performance': 'FALSE',
            'visitExperience': 'FALSE',
            'service': 'FALSE',
            'location': 'Gwydir St Car Park',
            'description': 'Nice buns',
            'email': '',
            'website': 'https://www.glazedandconfused.com',
            'phone': '01223 111111',
            'latLng': '52.199687,0.138813',
            'imageURL': '',
            'startTime': '10:30',
            'endTime': '16:30',
          }
        ];

        final result = await fetchExistingListings(mockClient);

        expect(result.length, 1);
        expect(result.first["title"], "Glazed and Confused");
      });

      test('retains cached listings data when app is restarted with API failure', () async {
        // Simulate first app launch: successfully fetch listings from API
        final initialMockResponse = {
          "values": [
            [
              "id",
              "visibleOnMap",
              "cancelled",
              "groupParent",
              "brickAndMortar",
              "emoji",
              "title",
              "subtitle",
              "groupID",
              "food",
              "shopping",
              "charityCommunityInfo",
              "performance",
              "visitExperience",
              "service",
              "location",
              "description",
              "email",
              "website",
              "phone",
              "latLng",
              "imageURL",
              "startTime",
              "endTime"
            ],
            [
              "1",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "🍩",
              "Glazed and Confused",
              "Doughnuts",
              "",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "Gwydir St Car Park",
              "Nice buns",
              "",
              "https://www.glazedandconfused.com",
              "01223 111111",
              "52.199687,0.138813",
              "",
              "10:30",
              "16:30",
            ],
            [
              "2",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "🍣",
              "Sushi Squad",
              "Sushi",
              "",
              "TRUE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "FALSE",
              "Sushi Bar",
              "Delicious sushi",
              "info@sushisquad.com",
              "https://www.sushisquad.com",
              "01223 222222",
              "52.200063,0.139313",
              "",
              "12:00",
              "16:40",
            ]
          ]
        };

        listings = [];

        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
              (_) async => http.Response.bytes(
            utf8.encode(jsonEncode(initialMockResponse)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );

        // First app launch: fetch and cache listings
        final firstLaunchResult = await fetchListings(mockClient);

        expect(firstLaunchResult.length, 2);
        expect(listings.length, 2);
        expect(listings.first["title"], "Glazed and Confused");
        expect(listings[1]["title"], "Sushi Squad");

        // Simulate app restart: call fetchExistingListings while API is down
        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('Internal Server Error', 500),
        );

        // Second app launch: API fails but cached listings should still be available
        final secondLaunchResult = await fetchExistingListings(mockClient);

        // Should return the cached listings from the first launch
        expect(secondLaunchResult.length, 2);
        expect(secondLaunchResult.first["title"], "Glazed and Confused");
        expect(secondLaunchResult[1]["title"], "Sushi Squad");
      });

      test('fetchExistingListings with empty cache returns empty list on API failure', () async {
        // Simulate fresh app install with API down
        listings = [];

        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('Internal Server Error', 500),
        );

        final result = await fetchExistingListings(mockClient);

        expect(result, []);
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(equals(10)); // Verifies retries happened
      });
    });
  });
}
