import 'mocks/listings_mocks.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    listings = [
      mockListing('cachedListing'),
    ];
  });

  test('waits for API failure before reporting cached listings', () async {
    final response = Completer<http.Response>();
    final requested = Completer<void>();
    var fallbacks = 0;
    final client = MockClient((_) {
      requested.complete();
      return response.future;
    });
    addTearDown(client.close);

    final fetch = fetchListings(client, onCacheFallback: () => fallbacks++);
    await requested.future;
    expect(fallbacks, 0);

    response.completeError(const SocketException('Offline'));
    final result = await fetch;
    expect(result.single['title'], 'Cached listing');
    expect(fallbacks, 1);
  });

  test('successful API refresh does not report a cache fallback', () async {
    var fallbacks = 0;
    final client = MockClient((_) async => http.Response(
          jsonEncode(mockListingsResponse([mockListing('glazedAndConfused')])),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ));
    addTearDown(client.close);

    final result = await fetchListings(client, onCacheFallback: () => fallbacks++);
    expect(result.single['title'], 'Glazed and Confused');
    expect(fallbacks, 0);
  });

  test('API failure without cached listings does not report a fallback', () async {
    listings = [];
    var fallbacks = 0;
    final client = MockClient((_) async => throw const SocketException('Offline'));
    addTearDown(client.close);

    final result = await fetchListings(client, onCacheFallback: () => fallbacks++);
    expect(result, isEmpty);
    expect(fallbacks, 0);
  });
}
