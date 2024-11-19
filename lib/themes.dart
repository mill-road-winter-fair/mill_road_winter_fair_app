// Define available themes
import 'package:flutter/material.dart';

final Map<String, ThemeData> appThemes = {
  'light': ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: const Color.fromRGBO(204, 51, 51, 1),
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: Colors.black,
      tertiary: const Color.fromRGBO(204, 51, 51, 1),
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      onSurfaceVariant: Colors.grey[700]!,
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
      backgroundColor: Colors.white,
    ),
  ),
  'dark': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: const Color.fromRGBO(30, 30, 30, 1.0),
        onPrimary: Colors.white,
        secondary: const Color.fromRGBO(44, 44, 44, 1.0),
        onSecondary: Colors.white,
        tertiary: const Color.fromRGBO(255, 196, 0, 1.0),
        error: Colors.red,
        onError: Colors.white,
        surface: const Color.fromRGBO(44, 44, 44, 1.0),
        onSurface: Colors.white,
        onSurfaceVariant: Colors.grey[300]!,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromRGBO(44, 44, 44, 1.0),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color.fromRGBO(255, 196, 0, 1.0),
        unselectedItemColor: Colors.grey,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color.fromRGBO(44, 44, 44, 1.0),
      ),
      elevatedButtonTheme:
          ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0), foregroundColor: Colors.white)),
      listTileTheme: const ListTileThemeData(tileColor: Color.fromRGBO(44, 44, 44, 1.0))),
  '2024': ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color.fromRGBO(37, 63, 128, 1.0),
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: Colors.black,
      tertiary: Color.fromRGBO(37, 63, 128, 1.0),
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
      backgroundColor: Colors.white,
    ),
  ),
  'highContrast': ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.highContrastDark(
        brightness: Brightness.dark,
        primary: Colors.black,
        onPrimary: Color.fromRGBO(255, 243, 0, 1.0),
        secondary: Colors.black,
        onSecondary: Color.fromRGBO(255, 243, 0, 1.0),
        tertiary: Color.fromRGBO(8, 255, 0, 1.0),
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.black,
        onSurface: Color.fromRGBO(255, 243, 0, 1.0),
        onSurfaceVariant: Color.fromRGBO(0, 255, 244, 1.0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Color.fromRGBO(255, 243, 0, 1.0),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color.fromRGBO(8, 255, 0, 1.0),
        unselectedItemColor: Colors.grey,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.black,
      ),
      elevatedButtonTheme:
          ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(8, 255, 0, 1.0), foregroundColor: Colors.black)),
      listTileTheme: const ListTileThemeData(tileColor: Colors.black)),
  'colourBlindFriendly': ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color.fromRGBO(102, 55, 133, 1.0),
      onPrimary: Colors.white,
      secondary: Color.fromRGBO(255, 196, 0, 1.0),
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
