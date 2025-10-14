import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Initialise global variable to hold listings
List<Map<String, dynamic>> listings = [];

// Fetch listings from Heroku caching layer
Future<List<Map<String, dynamic>>> fetchListings(http.Client client) async {
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    String herokuApi = dotenv.env['HEROKU_API'] ?? '';
    final uri = Uri.parse(herokuApi);

    final response = await client.get(uri);

    // Retry up to 10 times for transient failures
    if (response.statusCode != 200) {
      for (var i = 0; i < 9; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final retryResponse = await client.get(uri);
        if (retryResponse.statusCode == 200) {
          return _parseListings(retryResponse.body);
        }
      }
      throw HttpException('Heroku API returned ${response.statusCode}');
    }

    // Success
    final newListings = _parseListings(response.body);
    listings = newListings;
    return listings;
  } on SocketException catch (_) {
    debugPrint('⚠️ Network error: unable to reach server, using stale listings.');
    return listings.isNotEmpty ? listings : [];
  } on HttpException catch (e) {
    debugPrint('⚠️ Server responded with an error: $e');
    return listings.isNotEmpty ? listings : [];
  } on FormatException catch (e) {
    debugPrint('⚠️ Bad response format: $e');
    return listings.isNotEmpty ? listings : [];
  } catch (e, stack) {
    debugPrint('⚠️ Unexpected error fetching listings: $e');
    debugPrint(stack.toString());
    return listings.isNotEmpty ? listings : [];
  }
}

// Helper to parse JSON into the app’s listing structure
List<Map<String, dynamic>> _parseListings(String body) {
  final data = json.decode(body);
  final rows = data['values'] as List<dynamic>;
  final headers = rows.first as List<dynamic>;
  return rows.skip(1).map((row) {
    return Map<String, dynamic>.fromIterables(
      headers.cast<String>(),
      row.cast<dynamic>(),
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
