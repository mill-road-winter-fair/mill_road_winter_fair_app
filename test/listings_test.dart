import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mill_road_winter_fair_app/listings.dart';

@GenerateMocks([http.Client])
import 'listings_test.mocks.dart';

void main() {
  late MockClient mockClient;

  setUp(() async {
    mockClient = MockClient();
    dotenv.testLoad(fileInput: '''
    HEROKU_API=MOCK_API
    ANDROID_GOOGLE_MAPS_SDK_API_KEY=MOCK_KEY
    ANDROID_GOOGLE_MAPS_DIRECTIONS_API_KEY=MOCK_KEY
    IOS_GOOGLE_MAPS_SDK_API_KEY=MOCK_KEY
    IOS_GOOGLE_MAPS_DIRECTIONS_API_KEY=MOCK_KEY
    SIGNING_KEY=MOCK_CERT
    IOS_BUNDLE_ID=com.theberridge.mill_road_winter_fair_app
    ''');
  });

  group('fetchListings', () {
    test('retries 10 times and returns empty listings when status code is not 200 and we have no listings cached', () async {
      final invalidResponse = {};

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(jsonEncode(invalidResponse), 500),
      );

      final result = await fetchExistingListings(mockClient);

      expect(result, []);
      verify(mockClient.get(any)).called(equals(10));
    });

    test('returns a list of listings when response is valid', () async {
      final mockResponse = {
        "values": [
          ["displayName", "email", "endTime", "id", "latLng", "name", "phone", "primaryType", "secondaryType", "startTime", "tertiaryType", "website"],
          [
            "Glazed and Confused",
            "admin@glazedandconfued.com",
            "16:30",
            "1",
            "52.199687,0.138813",
            "glazedandconfused",
            "01223 111111",
            "Food",
            "Food",
            "10:30",
            "Doughnuts",
            "https://www.glazedandconfused.com"
          ]
        ]
      };

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(jsonEncode(mockResponse), 200),
      );

      final result = await fetchListings(mockClient);

      expect(result.length, 1);
      expect(result, [
        {
          'displayName': 'Glazed and Confused',
          'email': 'admin@glazedandconfued.com',
          'endTime': '16:30',
          'id': '1',
          'latLng': '52.199687,0.138813',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'website': 'https://www.glazedandconfused.com'
        }
      ]);
    });

    test('returns cached listings when status code is not 200', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('Error', 500),
      );

      final result = await fetchExistingListings(mockClient);

      expect(result, [
        {
          'displayName': 'Glazed and Confused',
          'email': 'admin@glazedandconfued.com',
          'endTime': '16:30',
          'id': '1',
          'latLng': '52.199687,0.138813',
          'name': 'glazedandconfused',
          'phone': '01223 111111',
          'primaryType': 'Food',
          'secondaryType': 'Food',
          'startTime': '10:30',
          'tertiaryType': 'Doughnuts',
          'website': 'https://www.glazedandconfused.com'
        }
      ]);
    });
  });

  group('fetchExistingListings', () {
    test('returns listings from fetchListings if no existing listings', () async {
      listings = [];

      final mockResponse = {
        "values": [
          ["displayName", "email", "endTime", "id", "latLng", "name", "phone", "primaryType", "secondaryType", "startTime", "tertiaryType", "website"],
          [
            "Glazed and Confused",
            "admin@glazedandconfued.com",
            "16:30",
            "1",
            "52.199687,0.138813",
            "glazedandconfused",
            "01223 111111",
            "Food",
            "Food",
            "10:30",
            "Doughnuts",
            "https://www.glazedandconfused.com"
          ]
        ]
      };

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(jsonEncode(mockResponse), 200),
      );

      final result = await fetchExistingListings(mockClient);

      expect(result.length, 1);
      expect(result.first["name"], "glazedandconfused");
    });

    test('returns existing listings if already populated', () async {
      listings = [
        {
          "displayName": "Glazed and Confused",
          "email": "admin@glazedandconfued.com",
          "endTime": "16:30",
          "id": "1",
          "name": "glazedandconfused",
          "phone": "01223 111111",
          "latLng": "52.199687,0.138813",
          "primaryType": "Food",
          "secondaryType": "Food",
          "startTime": "10:30",
          "tertiaryType": "Doughnuts",
          "website": "https://www.glazedandconfused.com"
        }
      ];

      final result = await fetchExistingListings(mockClient);

      expect(result.length, 1);
      expect(result.first["name"], "glazedandconfused");
    });
  });
}
