import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  onTest = true;

  group('Themes', () {
    test('getCategoryColor returns expected colors for light theme', () {
      expect(getCategoryColor('light', 'Food'), const Color.fromRGBO(255, 156, 26, 1.0));
      expect(getCategoryColor('light', 'Group-Food'), const Color.fromRGBO(255, 156, 26, 1.0));
      expect(getCategoryColor('light', 'Shopping'), const Color.fromRGBO(209, 81, 85, 1.0));
      expect(getCategoryColor('light', 'Music'), const Color.fromRGBO(190, 110, 230, 1.0));
      expect(getCategoryColor('light', 'Childrens'), const Color.fromRGBO(190, 110, 230, 1.0));
      expect(getCategoryColor('light', 'Dance'), const Color.fromRGBO(190, 110, 230, 1.0));
      expect(getCategoryColor('light', 'Other'), const Color.fromRGBO(190, 110, 230, 1.0));
      expect(getCategoryColor('light', 'Charity/Community/Info'), const Color.fromRGBO(190, 110, 230, 1.0));
      expect(getCategoryColor('light', 'Visit/Experience'), const Color.fromRGBO(79, 184, 75, 1.0));
      expect(getCategoryColor('light', 'Service'), const Color.fromRGBO(84, 145, 245, 1.0));
      expect(getCategoryColor('light', 'Unknown'), const Color.fromRGBO(150, 150, 150, 1.0));
    });

    test('getCategoryColor returns default for unknown theme', () {
      expect(getCategoryColor('not-a-theme', 'anything'), const Color.fromRGBO(150, 150, 150, 1.0));
    });

    testWidgets('getColoredMarker exercises multiple category branches', (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final types = [
        'Group-Food',
        'Food',
        'Group-Shopping',
        'Shopping',
        'Group-Music',
        'Music',
        'Group-Event',
        'Event',
        'Group-Place',
        'Place',
        'Group-Service',
        'Service-Information',
        'Service-FirstAid',
        'Service-Toilet',
        'Service'
      ];
      for (final t in types) {
        final m = await getColoredMarker(t, Colors.blue);
        expect(m, isNotNull);
        expect(m, equals(BitmapDescriptor.defaultMarker));
      }
    });

    testWidgets('getColoredMarker returns default for unknown category', (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final m = await getColoredMarker('Not-A-Real-Type', Colors.blue);
      expect(m, isNotNull);
      expect(m, equals(BitmapDescriptor.defaultMarker));
    });
  });
}
