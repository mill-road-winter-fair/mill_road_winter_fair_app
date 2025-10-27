import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Initialise global variable to hold listings
List<Map<String, dynamic>> listings = [];

// Fetch listings from Heroku caching layer
Future<List<Map<String, dynamic>>> fetchListings(http.Client client) async {
  debugPrint('fetchListings called');
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    String herokuApi = dotenv.env['HEROKU_API'] ?? '';
    final uri = Uri.parse(herokuApi);

    final response = await client.get(uri);
    debugPrint('API response status: ${response.statusCode}');

    // Retry up to 10 times for transient failures
    if (response.statusCode != 200) {
      for (var i = 0; i < 9; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final retryResponse = await client.get(uri);
        debugPrint('Retry ${i+1} response status: ${retryResponse.statusCode}');
        if (retryResponse.statusCode == 200) {
          debugPrint('Listings fetched after retry');
          return _parseListings(retryResponse.body);
        }
      }
      debugPrint('All retries failed');
      throw HttpException('Heroku API returned ${response.statusCode}');
    }

    // Success
    final newListings = _parseListings(response.body);
    listings = newListings;
    debugPrint('Listings successfully parsed and stored');
    return listings;
  } on SocketException catch (_) {
    debugPrint('\u26a0\ufe0f Network error: unable to reach server, using stale listings.');
    return listings.isNotEmpty ? listings : [];
  } on HttpException catch (e) {
    debugPrint('\u26a0\ufe0f Server responded with an error: $e');
    return listings.isNotEmpty ? listings : [];
  } on FormatException catch (e) {
    debugPrint('\u26a0\ufe0f Bad response format: $e');
    return listings.isNotEmpty ? listings : [];
  } catch (e, stack) {
    debugPrint('\u26a0\ufe0f Unexpected error fetching listings: $e');
    debugPrint(stack.toString());
    return listings.isNotEmpty ? listings : [];
  }
}

// Helper to parse JSON into the app’s listing structure
List<Map<String, dynamic>> _parseListings(String body) {
  final data = json.decode(body);
  final rows = data['values'] as List<dynamic>;
  // Defensive: ensure we have at least header row
  if (rows.isEmpty) return [];

  // Normalise headers to a list of strings
  final headers = (rows.first as List<dynamic>).map((h) => h?.toString() ?? '').toList();
  final headerCount = headers.length;

  return rows.skip(1).map((row) {
    // Each `row` (after row 1) should be a list of cells. Make a mutable copy.
    final cells = List<dynamic>.from(row as List<dynamic>);

    // If a row has fewer cells than headers, pad with empty strings so lengths match.
    if (cells.length < headerCount) {
      cells.addAll(List.filled(headerCount - cells.length, ''));
    } else if (cells.length > headerCount) {
      // If a row has extra cells, truncate to header length.
      cells.removeRange(headerCount, cells.length);
    }

    // Replace any explicit null cell values with empty strings to avoid nulls in the map.
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == null) cells[i] = '';
    }

    return Map<String, dynamic>.fromIterables(
      headers.cast<String>(),
      cells.cast<dynamic>(),
    );
  }).toList();
}

// Fetch listings only if we don't already have them
Future<List<Map<String, dynamic>>> fetchExistingListings(http.Client client) async {
  if (listings.isEmpty) {
    try {
      return await fetchListings(client);
    } catch (e) {
      debugPrint('Error in fetchExistingListings: $e');

      // If we already have cached listings, use them
      if (listings.isNotEmpty) {
        debugPrint('Using stale listings cache.');
        return listings;
      }

      return [];
    }
  }

  return listings;
}
