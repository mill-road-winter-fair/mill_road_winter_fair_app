import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

void main() async {
  test('getCategoryColor returns correct color for each map marker type whilst in light theme', () {
    final foodColor = getCategoryColor("light", "Food");
    final shoppingColor = getCategoryColor("light", "Shopping");
    final musicColor = getCategoryColor("light", "Music");
    final eventColor = getCategoryColor("light", "Event");
    final serviceColor = getCategoryColor("light", "Service");

    expect(foodColor, const Color.fromRGBO(242, 153, 0, 1.0));
    expect(shoppingColor, const Color.fromRGBO(209, 81, 85, 1.0));
    expect(musicColor, const Color.fromRGBO(190, 110, 230, 1.0));
    expect(eventColor, const Color.fromRGBO(243, 190, 66, 1.0));
    expect(serviceColor, const Color.fromRGBO(84, 145, 245, 1.0));

    final foodGroupColor = getCategoryColor("light", "Group-Food");
    final shoppingGroupColor = getCategoryColor("light", "Group-Shopping");
    final musicGroupColor = getCategoryColor("light", "Group-Music");
    final eventGroupColor = getCategoryColor("light", "Group-Event");
    final serviceGroupColor = getCategoryColor("light", "Group-Service");

    expect(foodGroupColor, const Color.fromRGBO(242, 153, 0, 1.0));
    expect(shoppingGroupColor, const Color.fromRGBO(209, 81, 85, 1.0));
    expect(musicGroupColor, const Color.fromRGBO(190, 110, 230, 1.0));
    expect(eventGroupColor, const Color.fromRGBO(243, 190, 66, 1.0));
    expect(serviceGroupColor, const Color.fromRGBO(84, 145, 245, 1.0));
  });

  test('getCategoryColor returns correct color for each map marker type whilst in dark theme', () {
    final foodColor = getCategoryColor("dark", "Food");
    final shoppingColor = getCategoryColor("dark", "Shopping");
    final musicColor = getCategoryColor("dark", "Music");
    final eventColor = getCategoryColor("dark", "Event");
    final serviceColor = getCategoryColor("dark", "Service");

    expect(foodColor, const Color.fromRGBO(189, 70, 0, 1.0));
    expect(shoppingColor, const Color.fromRGBO(204, 22, 22, 1.0));
    expect(musicColor, const Color.fromRGBO(183, 13, 204, 1.0));
    expect(eventColor, const Color.fromRGBO(255, 196, 0, 1.0));
    expect(serviceColor, const Color.fromRGBO(29, 112, 198, 1.0));

    final foodGroupColor = getCategoryColor("dark", "Group-Food");
    final shoppingGroupColor = getCategoryColor("dark", "Group-Shopping");
    final musicGroupColor = getCategoryColor("dark", "Group-Music");
    final eventGroupColor = getCategoryColor("dark", "Group-Event");
    final serviceGroupColor = getCategoryColor("dark", "Group-Service");

    expect(foodGroupColor, const Color.fromRGBO(189, 70, 0, 1.0));
    expect(shoppingGroupColor, const Color.fromRGBO(204, 22, 22, 1.0));
    expect(musicGroupColor, const Color.fromRGBO(183, 13, 204, 1.0));
    expect(eventGroupColor, const Color.fromRGBO(255, 196, 0, 1.0));
    expect(serviceGroupColor, const Color.fromRGBO(29, 112, 198, 1.0));
  });

  test('getCategoryColor returns correct color for each map marker type whilst in 2024 theme', () {
    final foodColor = getCategoryColor("2024", "Food");
    final shoppingColor = getCategoryColor("2024", "Shopping");
    final musicColor = getCategoryColor("2024", "Music");
    final eventColor = getCategoryColor("2024", "Event");
    final serviceColor = getCategoryColor("2024", "Service");

    expect(foodColor, const Color.fromRGBO(204, 110, 51, 1.0));
    expect(shoppingColor, const Color.fromRGBO(200, 0, 10, 1.0));
    expect(musicColor, const Color.fromRGBO(175, 98, 214, 1.0));
    expect(eventColor, const Color.fromRGBO(204, 161, 51, 1.0));
    expect(serviceColor, const Color.fromRGBO(37, 63, 128, 1.0));

    final foodGroupColor = getCategoryColor("2024", "Group-Food");
    final shoppingGroupColor = getCategoryColor("2024", "Group-Shopping");
    final musicGroupColor = getCategoryColor("2024", "Group-Music");
    final eventGroupColor = getCategoryColor("2024", "Group-Event");
    final serviceGroupColor = getCategoryColor("2024", "Group-Service");

    expect(foodGroupColor, const Color.fromRGBO(204, 110, 51, 1.0));
    expect(shoppingGroupColor, const Color.fromRGBO(200, 0, 10, 1.0));
    expect(musicGroupColor, const Color.fromRGBO(175, 98, 214, 1.0));
    expect(eventGroupColor, const Color.fromRGBO(204, 161, 51, 1.0));
    expect(serviceGroupColor, const Color.fromRGBO(37, 63, 128, 1.0));
  });

  test('getCategoryColor returns correct color for each map marker type whilst in highContrast theme', () {
    final foodColor = getCategoryColor("highContrast", "Food");
    final shoppingColor = getCategoryColor("highContrast", "Shopping");
    final musicColor = getCategoryColor("highContrast", "Music");
    final eventColor = getCategoryColor("highContrast", "Event");
    final serviceColor = getCategoryColor("highContrast", "Service");

    expect(foodColor, const Color.fromRGBO(131, 0, 0, 1.0));
    expect(shoppingColor, const Color.fromRGBO(5, 117, 0, 1.0));
    expect(musicColor, const Color.fromRGBO(125, 0, 140, 1.0));
    expect(eventColor, const Color.fromRGBO(151, 143, 0, 1.0));
    expect(serviceColor, const Color.fromRGBO(0, 120, 114, 1.0));

    final foodGroupColor = getCategoryColor("highContrast", "Group-Food");
    final shoppingGroupColor = getCategoryColor("highContrast", "Group-Shopping");
    final musicGroupColor = getCategoryColor("highContrast", "Group-Music");
    final eventGroupColor = getCategoryColor("highContrast", "Group-Event");
    final serviceGroupColor = getCategoryColor("highContrast", "Group-Service");

    expect(foodGroupColor, const Color.fromRGBO(131, 0, 0, 1.0));
    expect(shoppingGroupColor, const Color.fromRGBO(5, 117, 0, 1.0));
    expect(musicGroupColor, const Color.fromRGBO(125, 0, 140, 1.0));
    expect(eventGroupColor, const Color.fromRGBO(151, 143, 0, 1.0));
    expect(serviceGroupColor, const Color.fromRGBO(0, 120, 114, 1.0));
  });

  test('getCategoryColor returns correct color for each map marker type whilst in colourBlindFriendly theme', () {
    final foodColor = getCategoryColor("colourBlindFriendly", "Food");
    final shoppingColor = getCategoryColor("colourBlindFriendly", "Shopping");
    final musicColor = getCategoryColor("colourBlindFriendly", "Music");
    final eventColor = getCategoryColor("colourBlindFriendly", "Event");
    final serviceColor = getCategoryColor("colourBlindFriendly", "Service");

    expect(foodColor, const Color.fromRGBO(255, 100, 0, 1.0));
    expect(shoppingColor, const Color.fromRGBO(255, 0, 0, 1.0));
    expect(musicColor, const Color.fromRGBO(51, 204, 176, 1.0));
    expect(eventColor, const Color.fromRGBO(255, 196, 0, 1.0));
    expect(serviceColor, const Color.fromRGBO(153, 0, 255, 1.0));

    final foodGroupColor = getCategoryColor("colourBlindFriendly", "Group-Food");
    final shoppingGroupColor = getCategoryColor("colourBlindFriendly", "Group-Shopping");
    final musicGroupColor = getCategoryColor("colourBlindFriendly", "Group-Music");
    final eventGroupColor = getCategoryColor("colourBlindFriendly", "Group-Event");
    final serviceGroupColor = getCategoryColor("colourBlindFriendly", "Group-Service");

    expect(foodGroupColor, const Color.fromRGBO(255, 100, 0, 1.0));
    expect(shoppingGroupColor, const Color.fromRGBO(255, 0, 0, 1.0));
    expect(musicGroupColor, const Color.fromRGBO(51, 204, 176, 1.0));
    expect(eventGroupColor, const Color.fromRGBO(255, 196, 0, 1.0));
    expect(serviceGroupColor, const Color.fromRGBO(153, 0, 255, 1.0));
  });
}
