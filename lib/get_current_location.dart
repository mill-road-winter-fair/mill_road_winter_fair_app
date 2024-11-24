import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Initialise the user's current location at the global level as it needs to be used by the filtered listings page as well as the map page
late LatLng? currentLatLng;

Future<void> establishLocation() async {
  Position position = await getCurrentPosition();
  currentLatLng = LatLng(position.latitude, position.longitude);
}

// Helper function to get the current location
Future<Position> getCurrentPosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    throw Exception("Location services are disabled.");
  }

  // Request permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception("Location permissions are denied.");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception("Location permissions are permanently denied.");
  }

  // Get current position
  return await Geolocator.getCurrentPosition();
}
