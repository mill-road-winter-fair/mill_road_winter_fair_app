import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

int asTheCrowFlies(LatLng origin, LatLng destination) {
  debugPrint('asTheCrowFlies called: origin=$origin, destination=$destination');

  // Constant value for converting degrees to radians (π/180)
  const p = 0.017453292519943295;
  // Alias for the cosine function for easier usage in the formula
  const c = math.cos;

  // Haversine formula for calculating the central angle between two points on a sphere
  var a = 0.5 -
      c((destination.latitude - origin.latitude) * p) / 2 +
      c(origin.latitude * p) * c(destination.latitude * p) * (1 - c((destination.longitude - origin.longitude) * p)) / 2;

  // Why have a fudge factor? It's a UX thing
  // Estimating distances usings straight line routes means that the estimation is inevitably shorter than the actual walking route
  // Tapping 'Get Directions' for a destination that is supposedly 600 metres away and then seeing that it's actually 900 meters away feels bad
  // The fudge factor attempts to correct for these underestimations
  const fudgeFactor = 1.33;

  // Compute the great-circle distance in metres
  // Earth's radius is approximately 6,371 km (or 12,742 km for the diameter)
  // Multiply the central angle (in radians) by Earth's diameter and convert to metres
  // Apply the fudge factor (See above)
  // Round the figure to 0 decimal places
  var distanceMetres = (((12742 * math.asin(math.sqrt(a))) * 1000) * fudgeFactor).round();
  debugPrint('Distance calculated: $distanceMetres metres');
  return distanceMetres;
}
