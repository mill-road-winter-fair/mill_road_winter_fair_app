import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mill_road_winter_fair_app/globals.dart';

void main() {
  // We're on test
  onTest = true;

  TestWidgetsFlutterBinding.ensureInitialized();

  group('GetCurrentLocation', () {
    test('getCurrentPosition throws when location services disabled and no prompt', () async {
      // Configure globals to avoid calling Geolocator.openLocationSettings by ensuring promptedUserToEnableLocationServices >= 2
      locationServicesEnabled = false;
      promptedUserToEnableLocationServices = 2;

      // Call and expect an exception describing disabled services
      expect(() async => await getCurrentPosition(), throwsA(predicate((e) => e is Exception && e.toString().contains('Location services are disabled'))));
    });

    test('getCurrentPosition throws when permission denied forever', () async {
      // Configure globals so location services are enabled but permission is denied forever
      locationServicesEnabled = true;
      locationPermission = LocationPermission.deniedForever;

      // Call and expect an exception describing permanently denied permissions
      expect(() async => await getCurrentPosition(), throwsA(predicate((e) => e is Exception && e.toString().contains('permanently denied'))));
    });
  });
}
