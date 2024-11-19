// Define available themes
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create a ValueNotifier to hold the current theme
final ValueNotifier<String> themeNotifier = ValueNotifier(selectedThemeKey);

late String selectedThemeKey; // Currently selected theme key
late ThemeData selectedTheme; // Currently selected theme

final Map<String, ThemeData> appThemes = {
  'light': ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color.fromRGBO(204, 51, 51, 1),
      onPrimary: Colors.black,
      secondary: Colors.yellow,
      onSecondary: Colors.black,
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(204, 51, 51, 1),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color.fromRGBO(204, 51, 51, 1),
      unselectedItemColor: Colors.grey,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromRGBO(204, 51, 51, 1),
    ),
  ),

  'dark': ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,

      primary: Color.fromRGBO(30, 30, 30, 1.0),
      onPrimary: Colors.white,

      secondary: Colors.yellow,
      onSecondary: Colors.black,

      error: Colors.red,
      onError: Colors.white,

      surface: Colors.white,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(30, 30, 30, 1.0),
      foregroundColor: Colors.white,

    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color.fromRGBO(30, 30, 30, 1.0),
      unselectedItemColor: Colors.grey,

    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromRGBO(30, 30, 30, 1.0),

    ),
  ),

  '2024': ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,

      primary: Color.fromRGBO(37, 63, 128, 1.0),
      onPrimary: Colors.white,

      secondary: Colors.yellow,
      onSecondary: Colors.black,

      error: Colors.red,
      onError: Colors.white,

      surface: Colors.white,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(37, 63, 128, 1.0),
      foregroundColor: Colors.white,

    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color.fromRGBO(37, 63, 128, 1.0),
      unselectedItemColor: Colors.grey,

    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromRGBO(37, 63, 128, 1.0),

    ),
  ),

  'High Contrast': ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,

      primary: Color.fromRGBO(0, 0, 0, 1.0),
      onPrimary: Colors.white,

      secondary: Colors.yellow,
      onSecondary: Colors.black,

      error: Colors.red,
      onError: Colors.white,

      surface: Colors.white,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(0, 0, 0, 1.0),
      foregroundColor: Colors.white,

    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color.fromRGBO(0, 0, 0, 1.0),
      unselectedItemColor: Colors.grey,

    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromRGBO(0, 0, 0, 1.0),

    ),
  ),

  'Colour Blind Friendly': ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,

      primary: Color.fromRGBO(102, 55, 133, 1.0),
      onPrimary: Colors.white,

      secondary: Colors.yellow,
      onSecondary: Colors.black,

      error: Colors.red,
      onError: Colors.white,

      surface: Colors.white,
      onSurface: Colors.black,

    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(102, 55, 133, 1.0),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color.fromRGBO(102, 55, 133, 1.0),

      unselectedItemColor: Colors.grey,

    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromRGBO(102, 55, 133, 1.0),
    ),
  ),
};