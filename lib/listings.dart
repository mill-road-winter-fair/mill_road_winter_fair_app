import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Initialise global variable to hold listings (might want to switch this out for Firebase at some point)
List<Map<String, dynamic>> listings = [];

// Fetch listings from Google Sheets
Future<List<Map<String, dynamic>>> fetchListings(http.Client client) async {
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    String herokuApi = dotenv.env['HEROKU_API'] ?? '';

    final uri = Uri.parse(herokuApi);

    var response = await client.get(uri);

    if (response.statusCode != 200) {
      for (var i = 1; i < 10; i++) {
        sleep(const Duration(seconds: 2));
        var newResponse = await client.get(uri);

        // If response status code is still not 200, go to the next loop iteration
        if (newResponse.statusCode != 200) {
          continue;
        }

        response = newResponse;
        break;
      }

      // If response status code is still not 200 after 10 attempts
      if (response.statusCode != 200) {
        throw Exception('Heroku listings call failed to complete');
      }
    }

    // Transform the Sheets API response into JSON that matches the app's listings format
    final data = json.decode(response.body);
    final rows = data['values'] as List<dynamic>;
    final headers = rows.first as List<dynamic>; // The first row is headers
    List<Map<String, dynamic>> listings = rows.skip(1).map((row) {
      return Map<String, dynamic>.fromIterables(
        headers.cast<String>(),
        row.cast<dynamic>(),
      );
    }).toList();
    return listings;

    return [];
  } on Exception catch (e) {
    debugPrint('Error fetching Heroku listing data: $e');
    return [];
  } catch (e) {
    listings = [];
    return Future.error('Error fetching Heroku listing data: $e');
  }
}

// Fetch listings from Google Sheets if we don't have any listings
Future<List<Map<String, dynamic>>> fetchExistingListings(http.Client client) async {
  if (listings.isEmpty) {
    try {
      return fetchListings(client);
    } on Exception catch (e) {
      debugPrint('Error fetching Heroku listing data: $e');
      return [];
    } catch (e) {
      listings = [];
      return Future.error('Error fetching Heroku listing data: $e');
    }
  }

  return listings;
}
