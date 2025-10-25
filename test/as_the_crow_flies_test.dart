import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('asTheCrowFlies returns 0 when origin is null', () {
    const dest = LatLng(52.199687, 0.138813);
    final distance = asTheCrowFlies(null, dest);
    expect(distance, 0);
  });
}
