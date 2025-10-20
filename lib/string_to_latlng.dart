import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

LatLng stringToLatLng(String input) {
  debugPrint('stringToLatLng called: input=$input');
  try {
    // Split the string into latitude and longitude
    final parts = input.split(',');
    if (parts.length != 2) {
      throw const FormatException('Input string is not in "latitude,longitude" format');
    }

    // Parse the latitude and longitude
    final latitude = double.parse(parts[0].trim());
    final longitude = double.parse(parts[1].trim());
    debugPrint('Parsed LatLng: lat=$latitude, lng=$longitude');

    // Return the LatLng object
    return LatLng(latitude, longitude);
  } catch (e) {
    debugPrint('Error parsing LatLng: $e');
    throw Exception('Error parsing LatLng from string: $e');
  }
}
