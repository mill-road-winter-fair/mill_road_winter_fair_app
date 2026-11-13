import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/navigation_camera.dart';

void main() {
  const user = LatLng(52.2, 0.13);
  const route = [user, LatLng(52.2, 0.131)];

  Position fix({double speed = 1.2, double heading = 180, double accuracy = 10}) => Position(
    longitude: user.longitude, latitude: user.latitude, timestamp: DateTime(2026),
    accuracy: 5, altitude: 0, altitudeAccuracy: 0,
    heading: heading, headingAccuracy: accuracy, speed: speed, speedAccuracy: 0.2,
  );

  test('route supplies forward view without a GPS heading', () {
    final camera = navigationCamera(user, route);
    expect(camera.bearing, closeTo(90, 0.01));
    expect(camera.tilt, 60);
    expect(camera.zoom, 18.5);
    expect(camera.target.longitude, greaterThan(user.longitude));
    expect(Geolocator.distanceBetween(user.latitude, user.longitude,
      camera.target.latitude, camera.target.longitude), closeTo(20, 0.1));
  });

  test('reliable moving GPS heading determines camera direction', () {
    final camera = navigationCamera(user, route, position: fix());
    expect(camera.bearing, 180);
    expect(camera.target.latitude, lessThan(user.latitude));
  });

  test('stationary or unreliable headings fall back to the route', () {
    for (final position in [fix(speed: 0), fix(heading: -1), fix(heading: double.nan), fix(accuracy: 90)]) {
      expect(navigationCamera(user, route, position: position).bearing, closeTo(90, 0.01));
    }
  });

  test('progress along a bend uses the remaining route', () {
    const bend = LatLng(52.2, 0.131);
    final camera = navigationCamera(bend, [user, bend, const LatLng(52.201, 0.131)]);
    expect(camera.bearing, closeTo(0, 0.01));
    expect(camera.target.latitude, greaterThan(bend.latitude));
  });
}
