import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Uses the existing location fix and route only; no compass sensor is needed.
CameraPosition navigationCamera(LatLng user, List<LatLng> route, {Position? position}) {
  double bearing = 0;
  if (route.isNotEmpty) {
    var nearest = 0;
    var nearestDistance = double.infinity;
    for (var i = 0; i < route.length; i++) {
      final distance = Geolocator.distanceBetween(user.latitude, user.longitude, route[i].latitude, route[i].longitude);
      if (distance < nearestDistance) {
        nearest = i;
        nearestDistance = distance;
      }
    }
    for (final point in route.skip(nearest)) {
      if (Geolocator.distanceBetween(user.latitude, user.longitude, point.latitude, point.longitude) >= 8) {
        bearing = Geolocator.bearingBetween(user.latitude, user.longitude, point.latitude, point.longitude);
        break;
      }
    }
  }
  if (position != null && position.speed >= 0.8 &&
      position.heading.isFinite && position.heading >= 0 && position.heading < 360 &&
      position.headingAccuracy > 0 && position.headingAccuracy <= 30) {
    bearing = position.heading;
  }
  bearing = (bearing + 360) % 360;
  // Look slightly ahead so the user sits below centre, with more route visible.
  final radians = bearing * pi / 180;
  final target = LatLng(
    user.latitude + 20 * cos(radians) / 111320,
    user.longitude + 20 * sin(radians) / (111320 * cos(user.latitude * pi / 180)),
  );
  return CameraPosition(target: target, zoom: 18.5, tilt: 60, bearing: bearing);
}
