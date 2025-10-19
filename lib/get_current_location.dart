import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Initialise global variables for whether or not location services are enabled for the phone and permissions are granted to the app
late bool locationServicesEnabled;
late LocationPermission locationPermission;
// Initialise global variable for whether or not the user has been prompted to enable location services
int promptedUserToEnableLocationServices = 0;

// Initialise the user's current location at the global level as it needs to be used by the filtered listings page as well as the map page
LatLng? currentLatLng;

Future<void> establishLocation() async {
  debugPrint('establishLocation called');
  Position position = await getCurrentPosition();
  currentLatLng = LatLng(position.latitude, position.longitude);
  debugPrint('Current location established: $currentLatLng');
}

// Helper function to get the current location
Future<Position> getCurrentPosition() async {
  debugPrint('getCurrentPosition called');
  // Check if location services are enabled
  if (!locationServicesEnabled) {
    debugPrint('Location services disabled');
    // We want to prompt the user to enable location services if they have not already been prompted, but we only want to prompt them a few times
    if (promptedUserToEnableLocationServices < 2) {
      debugPrint('Prompting user to enable location services');
      await Geolocator.openLocationSettings();
      promptedUserToEnableLocationServices++;
    }
    throw Exception("Location services are disabled.");
  }

  // Request permissions
  if (locationPermission == LocationPermission.denied) {
    debugPrint('Location permission denied, requesting permission');
    locationPermission = await Geolocator.requestPermission();
    if (locationPermission == LocationPermission.denied) {
      debugPrint('Location permission still denied');
      throw Exception("Location permissions are denied.");
    }
  }

  if (locationPermission == LocationPermission.deniedForever) {
    debugPrint('Location permission denied forever');
    throw Exception("Location permissions are permanently denied.");
  }

  // Get current position
  Position pos = await Geolocator.getCurrentPosition();
  debugPrint('Position obtained: $pos');
  return pos;
}
