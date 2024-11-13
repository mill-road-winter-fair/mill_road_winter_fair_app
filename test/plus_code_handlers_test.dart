import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/plus_code_handlers.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([http.Client])
import 'plus_code_handlers_test.mocks.dart';

Future<void> main() async {

  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  const validPlusCode = '9F4254XQ+VG';
  final encodedValidPlusCode = Uri.encodeComponent(validPlusCode);
  const invalidPlusCode = 'INVALID_CODE';
  final encodedInvalidPlusCode = Uri.encodeComponent(invalidPlusCode);
  final urlWithValidPlusCode = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedValidPlusCode&key=$googleApiKey';
  final urlWithInvalidPlusCode = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedInvalidPlusCode&key=$googleApiKey';
  const lat = 52.199687;
  const lng = 0.138813;

  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
  });

  test('returns coordinates for a valid plus code', () async {
    final responseBody = {
      "results": [
        {
          "geometry": {
            "location": {"lat": lat, "lng": lng}
          }
        }
      ]
    };

    when(mockClient.get(Uri.parse(urlWithValidPlusCode)))
        .thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

    final result = await getCoordinatesFromPlusCode(validPlusCode, googleApiKey, mockClient);

    expect(result, isNotNull);
    expect(result, const LatLng(lat, lng));
  });

  test('returns null if results are empty', () async {
    final responseBody = json.encode({
      'results': [],
    });

    when(mockClient.get(Uri.parse(urlWithValidPlusCode)))
        .thenAnswer((_) async => http.Response(responseBody, 200));

    final result = await getCoordinatesFromPlusCode(validPlusCode, googleApiKey, mockClient);

    expect(result, isNull);
  });

  test('returns null if response status is not 200', () async {
    when(mockClient.get(Uri.parse(urlWithInvalidPlusCode)))
        .thenAnswer((_) async => http.Response('Error', 404));

    final result = await getCoordinatesFromPlusCode(invalidPlusCode, googleApiKey, mockClient);

    expect(result, isNull);
  });

  test('returns null if location data is missing', () async {
    final responseBody = json.encode({
      'results': [],
    });

    when(mockClient.get(Uri.parse(urlWithValidPlusCode)))
        .thenAnswer((_) async => http.Response(responseBody, 200));

    final result = await getCoordinatesFromPlusCode(validPlusCode, googleApiKey, mockClient);

    expect(result, isNull);
  });
}
