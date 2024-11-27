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
    String googleMapsAndSheetsApiKey = dotenv.env['GOOGLE_MAPS_AND_SHEETS_API_KEY'] ?? '';
    String googleSheetId = dotenv.env['GOOGLE_SHEET_ID'] ?? '';
    String googleSheetRange = dotenv.env['GOOGLE_SHEET_RANGE'] ?? '';

    final uri = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$googleSheetId/values/$googleSheetRange?key=$googleMapsAndSheetsApiKey');

    var response = await client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Google Sheets listings call failed to complete');
    }

    if (response.statusCode == 200) {
      // Sometimes column J in the Google Sheet is returning "#NAME?" instead of the latLng value
      // It only seems to occur when the API has not been called in some time
      // I don't know why this is happening (possibly something to do with custom formulas) but this is attempting to account for it
      if (response.body.contains('#NAME?')) {
        for (var i = 1; i < 10; i++) {
          sleep(const Duration(seconds: 2));
          var newResponse = await client.get(uri);

          if (newResponse.statusCode != 200) {
            throw Exception('Google Sheets listings call failed to complete');
          }

          if (newResponse.body.contains("#NAME?")) {
            continue;
          }

          response = newResponse;
          break;
        }

        // If the response still contains "#NAME?" after 10 attempts, throw an error
        if (response.body.contains("#NAME?")) {
          throw Exception("Google Sheets API returning #NAME? after 10 attempts");
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
    }

    return [];
  } on Exception catch (e) {
    debugPrint('Error fetching Google Sheets listing data: $e');
    return [];
  } catch (e) {
    listings = [];
    return Future.error('Error fetching Google Sheets listing data: $e');
  }
}

// Fetch listings from Google Sheets if we don't have any listings
Future<List<Map<String, dynamic>>> fetchExistingListings(http.Client client) async {
  if (listings.isEmpty || listings[0].containsValue('#NAME?')) {
    try {
      return fetchListings(client);
    } on Exception catch (e) {
      debugPrint('Error fetching Google Sheets listing data: $e');
      return [];
    } catch (e) {
      listings = [];
      return Future.error('Error fetching Google Sheets listing data: $e');
    }
  }

  return listings;
}
