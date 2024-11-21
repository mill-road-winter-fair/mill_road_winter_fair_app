import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

void main() async {
  test('convertDistanceUnits returns metres', () {
    final testDistance = convertDistanceUnits(697, DistanceUnits.metric);

    expect(testDistance, "697 m");
  });

  test('convertDistanceUnits returns kilometres', () {
    final testDistance = convertDistanceUnits(5248, DistanceUnits.metric);

    expect(testDistance, "5.25 km");
  });

  test('convertDistanceUnits returns feet', () {
    final testDistance = convertDistanceUnits(90, DistanceUnits.imperial);

    expect(testDistance, "295 ft");
  });

  test('convertDistanceUnits returns miles', () {
    final testDistance = convertDistanceUnits(3042, DistanceUnits.imperial);

    expect(testDistance, "1.89 miles");
  });
}
