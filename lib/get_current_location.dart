import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Initialise global variables for whether or not location services are enabled for the phone and permissions are granted to the app
late bool locationServicesEnabled;
late LocationPermission locationPermission;

// Initialise the user's current location at the global level as it needs to be used by the filtered listings page as well as the map page
LatLng? currentLatLng;

Future<void> establishLocation() async {
  Position position = await getCurrentPosition();
  currentLatLng = LatLng(position.latitude, position.longitude);
}

// Helper function to get the current location
Future<Position> getCurrentPosition() async {
  // Check if location services are enabled
  if (!locationServicesEnabled) {
    await Geolocator.openLocationSettings();
    throw Exception("Location services are disabled.");
  }

  // Request permissions
  if (locationPermission == LocationPermission.denied) {
    locationPermission = await Geolocator.requestPermission();
    if (locationPermission == LocationPermission.denied) {
      throw Exception("Location permissions are denied.");
    }
  }

  if (locationPermission == LocationPermission.deniedForever) {
    throw Exception("Location permissions are permanently denied.");
  }

  // Get current position
  return await Geolocator.getCurrentPosition();
}
