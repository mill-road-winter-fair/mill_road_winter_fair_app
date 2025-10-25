import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/string_to_latlng.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StringToLatLng', () {
    test('stringToLatLng parses valid input correctly', () {
      const input = '52.199838, 0.139016';
      final result = stringToLatLng(input);
      expect(result, isA<LatLng>());
      expect(result.latitude, closeTo(52.199838, 1e-6));
      expect(result.longitude, closeTo(0.139016, 1e-6));
    });

    test('stringToLatLng throws on invalid format (no comma)', () {
      const input = '52.199838 0.139016';
      expect(() => stringToLatLng(input), throwsA(isA<Exception>()));
    });

    test('stringToLatLng throws on non-numeric values', () {
      const input = 'notalat, notalong';
      expect(() => stringToLatLng(input), throwsA(isA<Exception>()));
    });
  });
}
