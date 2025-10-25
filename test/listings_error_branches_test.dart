import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/main.dart';

void main() {
  late MockClient mockClient;

  setUp(() async {
    // default noop client
    mockClient = MockClient((request) async => http.Response('[]', 200));
    dotenv.testLoad(fileInput: '''
    HEROKU_API=MOCK_API
    ''');
  });

  test('fetchListings returns cached listings on SocketException', () async {
    // Populate cached listings
    listings = [
      {'name': 'cached'}
    ];

    // Make the client throw a SocketException
    mockClient = MockClient((request) async {
      throw const SocketException('Failed host lookup');
    });

    final result = await fetchListings(mockClient as http.Client);

    expect(result, isNotNull);
    expect(result, equals(listings));
  });

  test('fetchListings handles bad format (FormatException) and returns cached listings', () async {
    listings = [
      {'name': 'cached2'}
    ];

    // Return an invalid JSON body that will cause json.decode to throw
    mockClient = MockClient((request) async => http.Response('not a json', 200));

    final result = await fetchListings(mockClient as http.Client);

    expect(result, equals(listings));
  });
}
