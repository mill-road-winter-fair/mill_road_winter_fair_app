// Define available themes
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/main.dart';

final Map<String, ThemeData> appThemes = {
  'light': ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: const Color.fromRGBO(166, 34, 43, 1),
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: Colors.black,
      tertiary: const Color.fromRGBO(166, 34, 43, 1),
      error: Colors.orange,
      onError: Colors.black,
      surface: Colors.white,
      surfaceDim: Colors.grey[300]!,
      onSurface: Colors.black,
      onSurfaceVariant: Colors.grey[700]!,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(166, 34, 43, 1),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color.fromRGBO(166, 34, 43, 1),
      unselectedItemColor: Colors.grey,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
    ),
    shadowColor: const Color.fromRGBO(0,0,0, 0.1),
  ),
  'dark': ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: const Color.fromRGBO(255, 196, 0, 1.0),
      onPrimary: Colors.black,
      secondary: const Color.fromRGBO(44, 44, 44, 1.0),
      onSecondary: Colors.white,
      tertiary: const Color.fromRGBO(255, 196, 0, 1.0),
      error: Colors.orange,
      onError: Colors.black,
      surface: const Color.fromRGBO(44, 44, 44, 1.0),
      surfaceDim: const Color.fromRGBO(30, 30, 30, 1.0),
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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0), foregroundColor: Colors.white, iconColor: Colors.white),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Color.fromRGBO(44, 44, 44, 1.0),
    ),
  ),
  '2024': ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color.fromRGBO(37, 63, 128, 1.0),
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: Colors.black,
      tertiary: Color.fromRGBO(37, 63, 128, 1.0),
      error: Colors.orange,
      onError: Colors.black,
      surface: Colors.white,
      surfaceDim: Colors.grey,
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
      error: Colors.orange,
      onError: Colors.black,
      surface: Colors.black,
      surfaceDim: Colors.grey,
      onSurface: Color.fromRGBO(255, 243, 0, 1.0),
      onSurfaceVariant: Color.fromRGBO(0, 255, 244, 1.0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Color.fromRGBO(255, 243, 0, 1.0),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: const Color.fromRGBO(8, 255, 0, 1.0),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color.fromRGBO(8, 255, 0, 1.0),
      unselectedItemColor: Colors.grey,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(4, 113, 0, 1.0), foregroundColor: Colors.white, iconColor: Colors.white),
    ),
    listTileTheme: const ListTileThemeData(tileColor: Colors.black),
  ),
  'colourBlindFriendly': ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color.fromRGBO(102, 55, 133, 1.0),
      onPrimary: Colors.white,
      secondary: Color.fromRGBO(255, 196, 0, 1.0),
      onSecondary: Colors.black,
      error: Colors.orange,
      onError: Colors.black,
      surface: Colors.white,
      surfaceDim: Colors.grey,
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
      backgroundColor: Colors.white,
    ),
  ),
};

// Standard Google Maps themes (designed with https://mapstyle.withgoogle.com/)
String standardMap =
    '[{"featureType":"poi.business","stylers":[{"visibility":"off"}]},{"featureType":"poi.park","elementType":"labels.text","stylers":[{"visibility":"off"}]}]';
String silverMap =
    '[{"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},{"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dadada"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]},{"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9c9c9"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}]';
String retroMap =
    '[{"elementType":"geometry","stylers":[{"color":"#ebe3cd"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#523735"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#f5f1e6"}]},{"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#c9b2a6"}]},{"featureType":"administrative.land_parcel","elementType":"geometry.stroke","stylers":[{"color":"#dcd2be"}]},{"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#ae9e90"}]},{"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#93817c"}]},{"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#a5b076"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#447530"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#f5f1e6"}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#fdfcf8"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f8c967"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#e9bc62"}]},{"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#e98d58"}]},{"featureType":"road.highway.controlled_access","elementType":"geometry.stroke","stylers":[{"color":"#db8555"}]},{"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#806b63"}]},{"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},{"featureType":"transit.line","elementType":"labels.text.fill","stylers":[{"color":"#8f7d77"}]},{"featureType":"transit.line","elementType":"labels.text.stroke","stylers":[{"color":"#ebe3cd"}]},{"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},{"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#b9d3c2"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#92998d"}]}]';
String darkMap =
    '[{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},{"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},{"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},{"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},{"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}]';
String nightMap =
    '[{"elementType":"geometry","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},{"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},{"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}]';
String aubergineMap =
    '[{"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},{"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},{"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64779e"}]},{"featureType":"administrative.province","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},{"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#334e87"}]},{"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#023e58"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},{"featureType":"poi","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},{"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#3C7680"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},{"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},{"featureType":"road.highway","elementType":"labels.text.stroke","stylers":[{"color":"#023e58"}]},{"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},{"featureType":"transit","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},{"featureType":"transit.line","elementType":"geometry.fill","stylers":[{"color":"#283d6a"}]},{"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#3a4762"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}]';

// Map themes taken from https://snazzymaps.com/
// https://snazzymaps.com/style/21/hopper
String highContrastMap =
    '[{"featureType":"water","elementType":"geometry","stylers":[{"hue":"#165c64"},{"saturation":34},{"lightness":-69},{"visibility":"on"}]},{"featureType":"landscape","elementType":"geometry","stylers":[{"hue":"#b7caaa"},{"saturation":-14},{"lightness":-18},{"visibility":"on"}]},{"featureType":"landscape.man_made","elementType":"all","stylers":[{"hue":"#cbdac1"},{"saturation":-6},{"lightness":-9},{"visibility":"on"}]},{"featureType":"road","elementType":"geometry","stylers":[{"hue":"#8d9b83"},{"saturation":-89},{"lightness":-12},{"visibility":"on"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"hue":"#d4dad0"},{"saturation":-88},{"lightness":54},{"visibility":"simplified"}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"hue":"#bdc5b6"},{"saturation":-89},{"lightness":-3},{"visibility":"simplified"}]},{"featureType":"road.local","elementType":"geometry","stylers":[{"hue":"#bdc5b6"},{"saturation":-89},{"lightness":-26},{"visibility":"on"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"hue":"#c17118"},{"saturation":61},{"lightness":-45},{"visibility":"on"}]},{"featureType":"poi.park","elementType":"all","stylers":[{"hue":"#8ba975"},{"saturation":-46},{"lightness":-28},{"visibility":"on"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"hue":"#a43218"},{"saturation":74},{"lightness":-51},{"visibility":"simplified"}]},{"featureType":"administrative.province","elementType":"all","stylers":[{"hue":"#ffffff"},{"saturation":0},{"lightness":100},{"visibility":"simplified"}]},{"featureType":"administrative.neighborhood","elementType":"all","stylers":[{"hue":"#ffffff"},{"saturation":0},{"lightness":100},{"visibility":"off"}]},{"featureType":"administrative.locality","elementType":"labels","stylers":[{"hue":"#ffffff"},{"saturation":0},{"lightness":100},{"visibility":"off"}]},{"featureType":"administrative.land_parcel","elementType":"all","stylers":[{"hue":"#ffffff"},{"saturation":0},{"lightness":100},{"visibility":"off"}]},{"featureType":"administrative","elementType":"all","stylers":[{"hue":"#3a3935"},{"saturation":5},{"lightness":-57},{"visibility":"off"}]},{"featureType":"poi.medical","elementType":"geometry","stylers":[{"hue":"#cba923"},{"saturation":50},{"lightness":-46},{"visibility":"on"}]}]';
// https://snazzymaps.com/style/18147/my-custom-style
String colourBlindMap =
    '[{"featureType":"all","elementType":"all","stylers":[{"saturation":"-100"}]},{"featureType":"landscape.man_made","elementType":"all","stylers":[{"color":"#f5f5f5"}]},{"featureType":"landscape.natural","elementType":"all","stylers":[{"color":"#f5f5f5"}]},{"featureType":"poi","elementType":"all","stylers":[{"color":"#e8e8e8"}]},{"featureType":"road","elementType":"geometry","stylers":[{"visibility":"simplified"},{"color":"#fe934c"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#666666"}]},{"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#9a96c5"}]}]';

Future<BitmapDescriptor> getColoredMarker(String primaryType, Color color) async {
  late String assetPath;
  final ByteData backdropData;

  switch (primaryType) {
    case 'Group-Food':
      assetPath = 'assets/mapMarkers/foodGroupMarker.png';
    case 'Food':
      assetPath = 'assets/mapMarkers/foodMarker.png';
    case 'Group-Shopping':
      assetPath = 'assets/mapMarkers/stallsGroupMarker.png';
    case 'Shopping':
      assetPath = 'assets/mapMarkers/stallsMarker.png';
    case 'Group-Music':
      assetPath = 'assets/mapMarkers/musicGroupMarker.png';
    case 'Music':
      assetPath = 'assets/mapMarkers/musicMarker.png';
    case 'Group-Event':
      assetPath = 'assets/mapMarkers/eventsGroupMarker.png';
    case 'Event':
      assetPath = 'assets/mapMarkers/eventsMarker.png';
    case 'Group-Service':
      assetPath = 'assets/mapMarkers/servicesGroupMarker.png';
    case 'Service-Information':
      assetPath = 'assets/mapMarkers/servicesInformationMarker.png';
    case 'Service-FirstAid':
      assetPath = 'assets/mapMarkers/servicesFirstAidMarker.png';
    case 'Service-Toilet':
      assetPath = 'assets/mapMarkers/servicesToiletsMarker.png';
    case 'Service':
      assetPath = 'assets/mapMarkers/servicesMarker.png';
  }

  // Adjust the asset path if this is a group and load the relevant backdrop image (frame)
  if (primaryType.contains('Group-')) {
    backdropData = await rootBundle.load("assets/mapMarkers/groupMarkerIconFrame.png");
  } else {
    backdropData = await rootBundle.load("assets/mapMarkers/markerIconFrame.png");
  }

  if (onTest == true) {
    // Return a default marker during unit tests to avoid crashes
    return BitmapDescriptor.defaultMarker;
  }
  try {
    int markerPixelSize = 288;
    final ui.Codec backdropCodec = await ui.instantiateImageCodec(
      backdropData.buffer.asUint8List(),
      targetWidth: markerPixelSize,
      targetHeight: markerPixelSize,
    );
    // The below line does not seem to work at all in the unit tests, it crashes the function without error
    final ui.FrameInfo backdropFrame = await backdropCodec.getNextFrame();
    final ui.Image backdropImage = backdropFrame.image;

    // Load the base image (to be colorized)
    final ByteData markerData = await rootBundle.load(assetPath);
    final ui.Codec markerCodec = await ui.instantiateImageCodec(
      markerData.buffer.asUint8List(),
      targetWidth: markerPixelSize,
      targetHeight: markerPixelSize,
    );
    // The below line does not seem to work at all in the unit tests, it crashes the function without error
    final ui.FrameInfo markerFrame = await markerCodec.getNextFrame();
    final ui.Image markerImage = markerFrame.image;

    // Create a canvas to draw both images
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Draw the backdrop image without any color filter
    final Paint backdropPaint = Paint(); // No color filter
    canvas.drawImage(backdropImage, Offset.zero, backdropPaint);

    // Draw the marker image on top with the color overlay
    final Paint markerPaint = Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn); // Apply color to the marker image
    canvas.drawImage(markerImage, Offset.zero, markerPaint);

    // Convert the final image to a BitmapDescriptor
    final ui.Image finalImage = await recorder.endRecording().toImage(
          markerImage.width,
          markerImage.height,
        );
    final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(pngBytes, imagePixelRatio: 1.0, height: 48.0, width: 48.0);
  } catch (e) {
    debugPrint("Custom marker rendering failed: $e");
    return BitmapDescriptor.defaultMarker;
  }
}

Color getCategoryColor(String selectedThemeKey, String primaryType) {
  if (selectedThemeKey == "light") {
    if (primaryType == "Food" || primaryType == "Group-Food") {
      Color color = const Color.fromRGBO(242, 153, 0, 1.0);
      return color;
    } else if (primaryType == "Shopping" || primaryType == "Group-Shopping") {
      Color color = const Color.fromRGBO(209, 81, 85, 1.0);
      return color;
    } else if (primaryType == "Music" || primaryType == "Group-Music") {
      Color color = const Color.fromRGBO(190, 110, 230, 1.0);
      return color;
    } else if (primaryType == "Event" || primaryType == "Group-Event") {
      Color color = const Color.fromRGBO(243, 190, 66, 1.0);
      return color;
    } else if (primaryType.startsWith("Service") || primaryType == "Group-Service") {
      Color color = const Color.fromRGBO(84, 145, 245, 1.0);
      return color;
    }

    // Default colour for markers with no category
    Color color = const Color.fromRGBO(0, 0, 0, 1.0);
    return color;
  } else if (selectedThemeKey == "dark") {
    if (primaryType == "Food" || primaryType == "Group-Food") {
      Color color = const Color.fromRGBO(189, 70, 0, 1.0);
      return color;
    } else if (primaryType == "Shopping" || primaryType == "Group-Shopping") {
      Color color = const Color.fromRGBO(204, 22, 22, 1.0);
      return color;
    } else if (primaryType == "Music" || primaryType == "Group-Music") {
      Color color = const Color.fromRGBO(183, 13, 204, 1.0);
      return color;
    } else if (primaryType == "Event" || primaryType == "Group-Event") {
      Color color = const Color.fromRGBO(255, 196, 0, 1.0);
      return color;
    } else if (primaryType.startsWith("Service") || primaryType == "Group-Service") {
      Color color = const Color.fromRGBO(29, 112, 198, 1.0);
      return color;
    }

    // Default colour for markers with no category
    Color color = const Color.fromRGBO(0, 0, 0, 1.0);
    return color;
  } else if (selectedThemeKey == "2024") {
    if (primaryType == "Food" || primaryType == "Group-Food") {
      Color color = const Color.fromRGBO(204, 110, 51, 1.0);
      return color;
    } else if (primaryType == "Shopping" || primaryType == "Group-Shopping") {
      Color color = const Color.fromRGBO(200, 0, 10, 1);
      return color;
    } else if (primaryType == "Music" || primaryType == "Group-Music") {
      Color color = const Color.fromRGBO(175, 98, 214, 1.0);
      return color;
    } else if (primaryType == "Event" || primaryType == "Group-Event") {
      Color color = const Color.fromRGBO(204, 161, 51, 1.0);
      return color;
    } else if (primaryType.startsWith("Service") || primaryType == "Group-Service") {
      Color color = const Color.fromRGBO(37, 63, 128, 1.0);
      return color;
    }

    // Default colour for markers with no category
    Color color = const Color.fromRGBO(0, 0, 0, 1.0);
    return color;
  } else if (selectedThemeKey == "highContrast") {
    if (primaryType == "Food" || primaryType == "Group-Food") {
      Color color = const Color.fromRGBO(131, 0, 0, 1.0);
      return color;
    } else if (primaryType == "Shopping" || primaryType == "Group-Shopping") {
      Color color = const Color.fromRGBO(5, 117, 0, 1.0);
      return color;
    } else if (primaryType == "Music" || primaryType == "Group-Music") {
      Color color = const Color.fromRGBO(125, 0, 140, 1.0);
      return color;
    } else if (primaryType == "Event" || primaryType == "Group-Event") {
      Color color = const Color.fromRGBO(151, 143, 0, 1.0);
      return color;
    } else if (primaryType.startsWith("Service") || primaryType == "Group-Service") {
      Color color = const Color.fromRGBO(0, 120, 114, 1.0);
      return color;
    }

    // Default colour for markers with no category
    Color color = const Color.fromRGBO(0, 0, 0, 1.0);
    return color;
  } else if (selectedThemeKey == "colourBlindFriendly") {
    if (primaryType == "Food" || primaryType == "Group-Food") {
      Color color = const Color.fromRGBO(255, 100, 0, 1.0);
      return color;
    } else if (primaryType == "Shopping" || primaryType == "Group-Shopping") {
      Color color = const Color.fromRGBO(255, 0, 0, 1.0);
      return color;
    } else if (primaryType == "Music" || primaryType == "Group-Music") {
      Color color = const Color.fromRGBO(51, 204, 176, 1.0);
      return color;
    } else if (primaryType == "Event" || primaryType == "Group-Event") {
      Color color = const Color.fromRGBO(255, 196, 0, 1.0);
      return color;
    } else if (primaryType.startsWith("Service") || primaryType == "Group-Service") {
      Color color = const Color.fromRGBO(153, 0, 255, 1.0);
      return color;
    }

    // Default colour for markers with no category
    Color color = const Color.fromRGBO(255, 0, 0, 1.0);
    return color;
  } else {
    // Default colour for markers with no theme and no category
    Color color = const Color.fromRGBO(255, 0, 0, 1.0);
    return color;
  }
}
