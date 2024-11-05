import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

Future<LatLng?> getCoordinatesFromPlusCode(
    String plusCode, String apiKey) async {
  final encodedPlusCode = Uri.encodeComponent(plusCode);
  final url =
      'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedPlusCode&key=$apiKey';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['results'] != null && data['results'].isNotEmpty) {
      final location = data['results'][0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
  }
  return null;
}
