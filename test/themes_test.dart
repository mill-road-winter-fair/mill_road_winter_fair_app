import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  onTest = true;

  group('Themes', () {
    test('getCategoryColor returns expected colors for light theme', () {
      expect(getCategoryColor('light', 'Food'), const Color.fromRGBO(242, 153, 0, 1.0));
      expect(getCategoryColor('light', 'Group-Food'), const Color.fromRGBO(242, 153, 0, 1.0));
      expect(getCategoryColor('light', 'Shopping'), const Color.fromRGBO(209, 81, 85, 1.0));
      expect(getCategoryColor('light', 'Music'), const Color.fromRGBO(190, 110, 230, 1.0));
      expect(getCategoryColor('light', 'Event'), const Color.fromRGBO(243, 190, 66, 1.0));
      expect(getCategoryColor('light', 'Service'), const Color.fromRGBO(84, 145, 245, 1.0));
      expect(getCategoryColor('light', 'Unknown'), const Color.fromRGBO(0, 0, 0, 1.0));
    });

    test('getCategoryColor returns expected colors for dark theme', () {
      expect(getCategoryColor('dark', 'Food'), const Color.fromRGBO(189, 70, 0, 1.0));
      expect(getCategoryColor('dark', 'Shopping'), const Color.fromRGBO(204, 22, 22, 1.0));
      expect(getCategoryColor('dark', 'Music'), const Color.fromRGBO(183, 13, 204, 1.0));
      expect(getCategoryColor('dark', 'Event'), const Color.fromRGBO(255, 196, 0, 1.0));
      expect(getCategoryColor('dark', 'Service'), const Color.fromRGBO(29, 112, 198, 1.0));
      expect(getCategoryColor('dark', 'Unknown'), const Color.fromRGBO(0, 0, 0, 1.0));
    });

    test('getCategoryColor returns expected colors for 2024 theme', () {
      expect(getCategoryColor('2024', 'Food'), const Color.fromRGBO(204, 110, 51, 1.0));
      expect(getCategoryColor('2024', 'Shopping'), const Color.fromRGBO(200, 0, 10, 1.0));
      expect(getCategoryColor('2024', 'Music'), const Color.fromRGBO(175, 98, 214, 1.0));
      expect(getCategoryColor('2024', 'Event'), const Color.fromRGBO(204, 161, 51, 1.0));
      expect(getCategoryColor('2024', 'Service'), const Color.fromRGBO(37, 63, 128, 1.0));
      expect(getCategoryColor('2024', 'Unknown'), const Color.fromRGBO(0, 0, 0, 1.0));
    });

    test('getCategoryColor returns expected colors for highContrast theme', () {
      expect(getCategoryColor('highContrast', 'Food'), const Color.fromRGBO(131, 0, 0, 1.0));
      expect(getCategoryColor('highContrast', 'Shopping'), const Color.fromRGBO(5, 117, 0, 1.0));
      expect(getCategoryColor('highContrast', 'Music'), const Color.fromRGBO(125, 0, 140, 1.0));
      expect(getCategoryColor('highContrast', 'Event'), const Color.fromRGBO(151, 143, 0, 1.0));
      expect(getCategoryColor('highContrast', 'Service'), const Color.fromRGBO(0, 120, 114, 1.0));
      expect(getCategoryColor('highContrast', 'Unknown'), const Color.fromRGBO(0, 0, 0, 1.0));
    });

    test('getCategoryColor returns expected colors for colourBlindFriendly theme', () {
      expect(getCategoryColor('colourBlindFriendly', 'Food'), const Color.fromRGBO(255, 100, 0, 1.0));
      expect(getCategoryColor('colourBlindFriendly', 'Shopping'), const Color.fromRGBO(255, 0, 0, 1.0));
      expect(getCategoryColor('colourBlindFriendly', 'Music'), const Color.fromRGBO(51, 204, 176, 1.0));
      expect(getCategoryColor('colourBlindFriendly', 'Event'), const Color.fromRGBO(255, 196, 0, 1.0));
      expect(getCategoryColor('colourBlindFriendly', 'Service'), const Color.fromRGBO(153, 0, 255, 1.0));
      expect(getCategoryColor('colourBlindFriendly', 'Unknown'), const Color.fromRGBO(255, 0, 0, 1.0));
    });

    test('getCategoryColor returns default for unknown theme', () {
      expect(getCategoryColor('not-a-theme', 'anything'), const Color.fromRGBO(255, 0, 0, 1.0));
    });

    testWidgets('getColoredMarker exercises multiple primaryType branches', (WidgetTester tester) async {
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

    testWidgets('getColoredMarker returns default for unknown primaryType', (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final m = await getColoredMarker('Not-A-Real-Type', Colors.blue);
      expect(m, isNotNull);
      expect(m, equals(BitmapDescriptor.defaultMarker));
    });
  });
}
