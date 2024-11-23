import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/map_page.dart';

// Initialise global variable to hold listings (might want to switch this out for Firebase at some point)
late List<Map<String, dynamic>> listings;

// Fetch listings from Google Sheets
Future<List<Map<String, dynamic>>> fetchListings(http.Client client) async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  String googleMapsAndSheetsApiKey = dotenv.env['GOOGLE_MAPS_AND_SHEETS_API_KEY'] ?? '';
  String googleSheetId = dotenv.env['GOOGLE_SHEET_ID'] ?? '';
  String googleSheetRange = dotenv.env['GOOGLE_SHEET_RANGE'] ?? '';

  final uri = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$googleSheetId/values/$googleSheetRange?key=$googleMapsAndSheetsApiKey');

  try {
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Transform the Sheets API response into JSON that matches your app's format
      final rows = data['values'] as List<dynamic>;
      final headers = rows.first as List<dynamic>; // Assume the first row is headers
      List<Map<String, dynamic>> listings = rows.skip(1).map((row) {
        return Map<String, dynamic>.fromIterables(
          headers.cast<String>(),
          row.cast<dynamic>(),
        );
      }).toList();
      return listings;
    } else {
      throw Exception('Failed to load Google Sheets data');
    }
  } catch (e) {
    throw 'Error fetching Google Sheets data: $e';
  }
}

// Fetch listings from Google Sheets if we don't have any listings
Future<List<Map<String, dynamic>>> fetchExistingListings(http.Client client) async {
  if (listings != []) {
    return listings;
  } else {
    List<Map<String, dynamic>> newListings = await fetchListings(client);
    mapPageKey.currentState?.setMarkerLists();
    mapPageKey.currentState?.addAllMarkers();
    return newListings;
  }
}
