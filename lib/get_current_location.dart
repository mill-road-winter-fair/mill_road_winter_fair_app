import 'dart:async';
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
  try {
    Position position = await getBestAvailablePosition();
    currentLatLng = LatLng(position.latitude, position.longitude);
    debugPrint('Current location established: $currentLatLng');
  } catch (e) {
    // getCurrentPosition (getBestAvailablePosition) already attempts the last-known fallback where appropriate.
    // Keep establishLocation simple: if we couldn't get a position, clear currentLatLng and propagate the error.
    debugPrint('establishLocation: failed to get current position: $e');

    // If no position could be established, retain any previous location but propagate the error
    rethrow;
  }
}

// Helper function that centralises the full logic for obtaining a position: check services/permissions, try current
// position with timeout, and fall back to the last known position.
Future<Position> getBestAvailablePosition() async {
  debugPrint('getBestAvailablePosition called');

  // Ensure we have up-to-date information about whether services and permissions are available
  await updateLocationStatus();

  // Check if location services are enabled
  if (!locationServicesEnabled) {
    debugPrint('Location services disabled');
    // We want to prompt the user to enable location services if they have not already been prompted, but we only want to prompt them a few times
    if (promptedUserToEnableLocationServices < 2) {
      debugPrint('Prompting user to enable location services');
      try {
        await Geolocator.openLocationSettings();
      } catch (e) {
        debugPrint('Failed to open location settings: $e');
      }
      promptedUserToEnableLocationServices++;
    }
    throw Exception("Location services are disabled.");
  }

  // Request permissions if necessary
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

  // Try to obtain a fresh GPS fix with a reasonable timeout, falling back to last-known if necessary
  try {
    final Position pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 2));
    debugPrint('Position obtained: $pos');
    return pos;
  } on TimeoutException catch (e) {
    debugPrint('getBestAvailablePosition timed out: $e');
    final Position? last = await _getLastKnownPositionSafely();
    if (last != null) {
      debugPrint('Using last known position due to timeout: $last');
      return last;
    }
    throw Exception('Unable to obtain GPS fix (timed out).');
  } on Exception catch (e) {
    debugPrint('Error obtaining position in getBestAvailablePosition: $e');
    final Position? last = await _getLastKnownPositionSafely();
    if (last != null) {
      debugPrint('Using last known position due to error: $last');
      return last;
    }
    rethrow;
  }
}

// Helper to safely fetch the last known position
Future<Position?> _getLastKnownPositionSafely() async {
  try {
    return await Geolocator.getLastKnownPosition();
  } catch (e) {
    debugPrint('Error obtaining last known position: $e');
    return null;
  }
}

// Helper to refresh global variables about service availability and permissions
Future<void> updateLocationStatus() async {
  // Only assign globals if the platform calls succeed. If they throw (e.g. during unit tests where the plugin isn't
  // available), preserve any existing values so test setup can control them.
  try {
    final bool servicesEnabled = await Geolocator.isLocationServiceEnabled();
    locationServicesEnabled = servicesEnabled;
  } catch (e) {
    // Don't overwrite locationServicesEnabled; tests or main() may have already provided a value.
    debugPrint('updateLocationStatus: error checking location services: $e');
  }

  try {
    final LocationPermission perm = await Geolocator.checkPermission();
    locationPermission = perm;
  } catch (e) {
    // Don't overwrite locationPermission; tests or main() may have already provided a value.
    debugPrint('updateLocationStatus: error checking location permission: $e');
  }
}
