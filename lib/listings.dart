import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences key for storing cached listings as JSON
const String _listingsCacheKey = 'cached_listings_json';

// Save listings to SharedPreferences
Future<void> _saveListingsToCache(
    List<Map<String, dynamic>> listingsToCache) async {
  final timer = Stopwatch()..start();
  debugPrint('[Listings] Cache write starting: count=${listingsToCache.length}');
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(listingsToCache);
    final saved = await prefs.setString(_listingsCacheKey, jsonString);
    debugPrint('[Listings] Cache write completed: success=$saved, '
        'count=${listingsToCache.length}, characters=${jsonString.length}, '
        'elapsedMs=${timer.elapsedMilliseconds}');
  } catch (e) {
    debugPrint('[Listings] Cache write failed (${e.runtimeType}): $e');
  }
}

// Load listings from SharedPreferences
Future<List<Map<String, dynamic>>> loadListingsFromCache() async {
  final timer = Stopwatch()..start();
  debugPrint('[Listings] Cache read starting: key=$_listingsCacheKey');
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_listingsCacheKey);
    debugPrint('[Listings] Cache read: present=${jsonString != null}, '
        'characters=${jsonString?.length ?? 0}');

    if (jsonString == null || jsonString.isEmpty) {
      debugPrint('[Listings] Cache missing or empty; returning 0 listings');
      return [];
    }

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final result = decoded.cast<Map<String, dynamic>>();
    debugPrint('[Listings] Cache decoded: count=${result.length}, '
        'elapsedMs=${timer.elapsedMilliseconds}');
    return result;
  } catch (e) {
    debugPrint('[Listings] Cache read/decode failed (${e.runtimeType}): $e; '
        'returning 0 listings');
    return [];
  }
}

// Fetch listings from Heroku caching layer
Future<List<Map<String, dynamic>>> fetchListings(http.Client client) async {
  final timer = Stopwatch()..start();
  debugPrint('[Listings] Fetch starting: memoryCount=${listings.length}');
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    String herokuApi = dotenv.env['HEROKU_API'] ?? '';
    String herokuApiKey = dotenv.env['HEROKU_API_KEY'] ?? '';
    final uri = Uri.parse(herokuApi);

    debugPrint('[Listings] HTTP attempt 1/10 starting: '
        'endpointConfigured=${herokuApi.isNotEmpty}, '
        'apiKeyConfigured=${herokuApiKey.isNotEmpty}');
    final response =
        await client.get(uri, headers: {'X-Api-Key': herokuApiKey});
    debugPrint('[Listings] HTTP attempt 1/10 completed: '
        'status=${response.statusCode}, bytes=${response.bodyBytes.length}, '
        'elapsedMs=${timer.elapsedMilliseconds}');

    // Retry up to 10 times for transient failures
    if (response.statusCode != 200) {
      for (var i = 0; i < 9; i++) {
        debugPrint('[Listings] HTTP attempt ${i + 2}/10 scheduled in 2 seconds');
        await Future.delayed(const Duration(seconds: 2));
        debugPrint('[Listings] HTTP attempt ${i + 2}/10 starting');
        final retryResponse = await client.get(uri);
        debugPrint(
            '[Listings] HTTP attempt ${i + 2}/10 completed: '
            'status=${retryResponse.statusCode}, '
            'elapsedMs=${timer.elapsedMilliseconds}');
        if (retryResponse.statusCode == 200) {
          debugPrint('[Listings] Fetch succeeded after retry');
          final newListings = _parseListings(retryResponse.body);
          if (newListings.isEmpty) {
            throw const FormatException('The listings response was empty');
          }
          listings = newListings;
          // Save to persistent cache
          await _saveListingsToCache(newListings);
          return newListings;
        }
      }
      debugPrint('[Listings] All HTTP attempts failed');
      throw HttpException('Heroku API returned ${response.statusCode}');
    }

    // Success
    final newListings = _parseListings(response.body);
    if (newListings.isEmpty) {
      throw const FormatException('The listings response was empty');
    }
    listings = newListings;
    debugPrint('[Listings] Network data stored in memory: count=${listings.length}');
    // Save to persistent cache
    await _saveListingsToCache(newListings);
    return newListings;
  } on SocketException catch (e) {
    debugPrint(
        '[Listings] Network error (${e.runtimeType}): $e; trying cache');
    // Try to load from persistent cache
    if (listings.isEmpty) {
      debugPrint('[Listings] Memory empty; falling back to persistent cache');
      listings = await loadListingsFromCache();
    }
    return listings.isNotEmpty ? listings : [];
  } on HttpException catch (e) {
    debugPrint('[Listings] Server error: $e; trying cache');
    // Try to load from persistent cache
    if (listings.isEmpty) {
      debugPrint('[Listings] Memory empty; falling back to persistent cache');
      listings = await loadListingsFromCache();
    }
    return listings.isNotEmpty ? listings : [];
  } on FormatException catch (e) {
    debugPrint('[Listings] Bad response format: $e; trying cache');
    // Try to load from persistent cache
    if (listings.isEmpty) {
      debugPrint('[Listings] Memory empty; falling back to persistent cache');
      listings = await loadListingsFromCache();
    }
    return listings.isNotEmpty ? listings : [];
  } catch (e, stack) {
    debugPrint('[Listings] Fetch error (${e.runtimeType}): $e; trying cache');
    debugPrint(stack.toString());
    // Try to load from persistent cache
    if (listings.isEmpty) {
      debugPrint('[Listings] Memory empty; falling back to persistent cache');
      listings = await loadListingsFromCache();
    }
    return listings.isNotEmpty ? listings : [];
  } finally {
    debugPrint('[Listings] Fetch finished: availableCount=${listings.length}, '
        'elapsedMs=${timer.elapsedMilliseconds}');
  }
}

// Helper to parse JSON into the app’s listing structure
List<Map<String, dynamic>> _parseListings(String body) {
  debugPrint('[Listings] Parsing network response');
  final data = json.decode(body);
  final rows = data['values'] as List<dynamic>;
  debugPrint('[Listings] Response rows including header: ${rows.length}');
  // Defensive: ensure we have at least header row
  if (rows.isEmpty) return [];

  // Normalise headers to a list of strings
  final headers =
      (rows.first as List<dynamic>).map((h) => h?.toString() ?? '').toList();
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
Future<List<Map<String, dynamic>>> fetchExistingListings(
    http.Client client) async {
  debugPrint('[Listings] fetchExistingListings: memoryCount=${listings.length}, '
      'fetchRequired=${listings.isEmpty}');
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
