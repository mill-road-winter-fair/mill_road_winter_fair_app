import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mill_road_winter_fair_app/listings.dart';

// Import the generated mocks from the existing test harness
import 'listings_test.mocks.dart';

void main() {
  late MockClient mockClient;

  setUp(() async {
    mockClient = MockClient();
    listings = [];
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

  test('handles rows with missing cells by padding to headers', () async {
    final mockResponse = {
      "values": [
        ["displayName", "email", "endTime", "id", "latLng", "name", "phone", "primaryType", "secondaryType", "startTime", "tertiaryType", "website"],
        [
          "Glazed and Confused",
          "admin@glazedandconfued.com",
          "", // endTime is blank (cleared cell)
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
    expect(result.first['endTime'], '');
    expect(result.first['displayName'], 'Glazed and Confused');
    expect(result.first['id'], '1');
  });

  test('handles explicit null cells by converting them to empty strings', () async {
    final mockResponse = {
      "values": [
        ["displayName", "email", "endTime", "id", "latLng", "name", "phone", "primaryType", "secondaryType", "startTime", "tertiaryType", "website"],
        [
          "Glazed and Confused",
          "admin@glazedandconfued.com",
          null,
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
    expect(result.first['endTime'], '');
  });
}
