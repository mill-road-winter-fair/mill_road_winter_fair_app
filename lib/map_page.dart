import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/listings_may_change_reminder.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/string_to_latlng.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define a GlobalKey for MapPageState:
final GlobalKey<MapPageState> mapPageKey = GlobalKey<MapPageState>();

class MapPage extends StatefulWidget {
  final List<Map<String, dynamic>> listings;

  const MapPage({required this.listings, super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  late Future<List<Map<String, dynamic>>> _fetchListings;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{}; // For displaying the map markers
  final Set<Polyline> _polylines = {}; // For displaying the route polyline
  late PolylinePoints _polylinePoints; // For decoding points
  Map<String, BitmapDescriptor> bitmapDescriptors = <String, BitmapDescriptor>{}; // Cache of custom BitmapDescriptors to use as map markers
  late double _mapBearing;
  late MapType mapType;
  late double _compassBearing;
  double? mapWidth;
  double? mapHeight;
  bool _navigationInProgress = false;
  String? _distanceToDestination;
  StreamSubscription<Position>? _positionStream;
  LatLng? _destination; // To store the destination
  GoogleMapController? _controller;
  IconData _layersIcon = Icons.satellite_alt;
  bool isRefreshing = false;

  @override
  void initState() {
    _polylinePoints = PolylinePoints();
    _fetchListings = fetchExistingListings(http.Client());
    createAllMarkerBitmaps();
    addAllVisibleMarkers(false);
    establishLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ListingUpdateNotifier.maybeShowNotice(context);
    });
    super.initState();
  }

  void addAllVisibleMarkers(bool onTest) {
    for (var listing in listings) {
      if (listing['visibleOnMap'] == 'TRUE') {
        // Add Group markers
        if (listing['primaryType'].startsWith('Group-')) {
          addGroupMarker(listing, onTest);
        }
        // Add Specific markers
        if (!listing['primaryType'].startsWith('Group-')) {
          addSpecificMarker(listing, onTest);
        }
      }
    }
  }

  Future<bool> createAllMarkerBitmaps() async {
    for (var listingType in 'Food, Shopping, Music, Event, Service, Group-Food, Group-Shopping, Group-Music, Group-Event, Group-Service'.split(', ')) {
      BitmapDescriptor newBitmapDescriptor = await getColoredMarker(listingType, getCategoryColor(selectedThemeKey, listingType));
      bitmapDescriptors[listingType] = newBitmapDescriptor;
    }
    if (bitmapDescriptors.isEmpty) {
      debugPrint('Error: created zero bitmap descriptors');
      return false;
    } else {
      return true;
    }
  }

  void addGroupMarker(listing, bool onTest) async {
    LatLng destinationLatLng = stringToLatLng(listing['latLng']);
    MarkerId markerId = MarkerId(listing['id'].toString());
    Color color = getCategoryColor(selectedThemeKey, listing['primaryType']);
    late BitmapDescriptor customMarker;

    if (onTest == false) {
      customMarker = await getColoredMarker(listing['primaryType'], color);
    } else {
      double hue = HSVColor.fromColor(color).hue;
      customMarker = bitmapDescriptors[listing['primaryType']] ?? BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    Marker newMarker = Marker(
      markerId: markerId,
      position: destinationLatLng,
      icon: customMarker,
      visible: true,
      onTap: () {
        establishLocation();

        // Helper to normalise primaryType by stripping "Group-" prefix if present
        String normalisePrimaryType(String type) {
          return type.startsWith("Group-") ? type.substring(6) : type;
        }

        // Filter listings where both normalised primaryType and secondaryType match
        List<Map<String, dynamic>> relatedListings = listings.where((l) {
          final listingPrimary = normalisePrimaryType(l['primaryType'] ?? '');
          final targetPrimary = normalisePrimaryType(listing['primaryType'] ?? '');
          final listingSecondary = l['secondaryType'] ?? '';
          final targetSecondary = listing['secondaryType'] ?? '';

          return listingPrimary == targetPrimary && listingSecondary == targetSecondary;
        }).toList();

        // Sort listings: Group first → startTime → displayName
        relatedListings.sort((a, b) {
          if (a['primaryType'].startsWith("Group") && !b['primaryType'].startsWith("Group")) {
            return -1;
          } else if (b['primaryType'].startsWith("Group") && !a['primaryType'].startsWith("Group")) {
            return 1;
          }

          final timeCompare = a['startTime'].compareTo(b['startTime']);
          if (timeCompare != 0) return timeCompare;

          return a['name'].compareTo(b['name']);
        });

        showModalBottomSheet(
          context: context,
          showDragHandle: false,
          enableDrag: false,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext context) {
            double screenHeight = MediaQuery.of(context).size.height;
            // Estimate the height of a SimplifiedListingInfoSheet in pixels
            double estimatedItemHeight = 145;
            // Estimate the total height of the bottom sheet
            double estimatedSheetHeight = relatedListings.length * estimatedItemHeight;
            // Set the minimum size of the modalBottomSheet based on either the estimatedSheetHeight or 2/3 of the screen, whichever is lower
            double minFraction = min((estimatedSheetHeight / screenHeight), 0.66);
            // Set the maximum size of the modalBottomSheet based on either the estimatedSheetHeight or the whole screen, whichever is lower
            double maxFraction = min((estimatedSheetHeight / screenHeight), 0.9);

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: minFraction,
              minChildSize: minFraction,
              maxChildSize: maxFraction,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    thickness: 4,
                    radius: const Radius.circular(8),
                    child: ListView.separated(
                      controller: scrollController,
                      separatorBuilder: (BuildContext context, int index) => Divider(color: Colors.grey[350]),
                      itemCount: relatedListings.length,
                      itemBuilder: (context, index) {
                        final rel = relatedListings[index];
                        int approximateDistanceMetres = asTheCrowFlies(
                          currentLatLng,
                          stringToLatLng(rel['latLng']),
                        );

                        if (rel['primaryType'].startsWith("Group")) {
                          return GroupListingInfoSheet(
                            title: rel['displayName'],
                            categories: "${rel['tertiaryType']}",
                            openingTimes: "${rel['startTime']} - ${rel['endTime']}",
                            approxDistance: 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}',
                          );
                        } else {
                          return SimplifiedListingInfoSheet(
                            title: rel['displayName'],
                            categories: "${rel['secondaryType']} • ${rel['tertiaryType']}",
                            openingTimes: "${rel['startTime']} - ${rel['endTime']}",
                            phoneNumber: rel['phone'],
                            website: rel['website'],
                            onGetDirections: () => getDirections(
                              rel['id'],
                              stringToLatLng(rel['latLng']),
                              true,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    setState(() {
      markers[markerId] = newMarker;
    });
  }

  void addSpecificMarker(listing, bool onTest) async {
    LatLng destinationLatLng = stringToLatLng(listing['latLng']);
    MarkerId markerId = MarkerId(listing['id'].toString());
    Color color = getCategoryColor(selectedThemeKey, listing['primaryType']);
    late BitmapDescriptor customMarker;
    if (onTest == false) {
      customMarker = await getColoredMarker(listing['primaryType'], color);
    } else {
      double hue = HSVColor.fromColor(color).hue;
      customMarker = bitmapDescriptors[listing['primaryType']] ?? BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    Marker newMarker = Marker(
      markerId: markerId,
      position: destinationLatLng,
      icon: customMarker,
      visible: true,
      onTap: () {
        HapticFeedback.lightImpact();
        // Update user's location
        establishLocation();
        int approximateDistanceMetres = asTheCrowFlies(currentLatLng, destinationLatLng);
        // Show bottom sheet with listing information
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return SpecificListingInfoSheet(
              title: listing['displayName'],
              categories: "${listing['secondaryType']} • ${listing['tertiaryType']}",
              openingTimes: "${listing['startTime']} - ${listing['endTime']}",
              approxDistance: 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}',
              phoneNumber: listing['phone'],
              website: listing['website'],
              onGetDirections: () => getDirections(listing['id'], destinationLatLng, true),
            );
          },
        );
      },
    );

    setState(() {
      markers[markerId] = newMarker;
    });
  }

  void clearAllMarkers() {
    setState(() {
      markers.clear();
    });
  }

  Future<void> getDirections(String id, LatLng destination, bool navigatorPop) async {
    // Pop the navigator if told to
    if (navigatorPop == true) {
      Navigator.pop(context);
    }

    // Clear any existing polylines
    setState(() {
      _polylines.clear(); // Clear any existing polylines
      clearAllMarkers(); // Clear any existing map markers
    });

    // If user has location tracking enabled
    if (currentLatLng != null) {
      // Get the user's current location
      Position position = await getCurrentPosition();
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      await updatePolyline(currentLatLng, destination);
      // Set the camera position once, at the beginning of the navigation
      _setMapCameraToFitPolyline(_polylines);

      // Start location updates
      await startLocationUpdates(destination);
    } else {
      Fluttertoast.showToast(
        msg: 'Location services and permissions are required to determine directions',
        gravity: ToastGravity.CENTER,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
        fontSize: 16,
        toastLength: Toast.LENGTH_LONG,
      );
    }

    // Add destination map marker
    Map<String, dynamic> destinationListing = listings.firstWhere((element) => element['id'] == id);
    addSpecificMarker(destinationListing, false);

    // Set navigation as in progress
    _navigationInProgress = true;
  }

  @override
  void dispose() {
    // Cancel the location subscription when the page is disposed
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> startLocationUpdates(LatLng destination) async {
    // Store the destination
    _destination = destination;

    // Start listening for location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((Position position) async {
      // Update the user's current location
      currentLatLng = LatLng(position.latitude, position.longitude);

      // If a destination is set, get new directions and update the polyline
      if (_destination != null) {
        await updatePolyline(currentLatLng!, _destination!);
      }
    });
  }

  Future<void> updatePolyline(LatLng origin, LatLng destination) async {
    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");
      String googleMapsDirectionsApiKey = "";
      String androidSigningKey = dotenv.env['SIGNING_KEY'] ?? '';
      String iosBundleId = dotenv.env['IOS_BUNDLE_ID'] ?? '';

      // Define headers based on platform
      Map<String, String> headers;
      if (Platform.isAndroid) {
        googleMapsDirectionsApiKey = dotenv.env['ANDROID_GOOGLE_MAPS_DIRECTIONS_API_KEY'] ?? '';
        headers = {
          "X-Android-Package": "com.theberridge.mill_road_winter_fair_app",
          "X-Android-Cert": androidSigningKey,
        };
      } else if (Platform.isIOS) {
        googleMapsDirectionsApiKey = dotenv.env['IOS_GOOGLE_MAPS_DIRECTIONS_API_KEY'] ?? '';
        headers = {
          "X-Ios-Bundle-Identifier": iosBundleId,
        };
      } else {
        headers = {};
      }

      if (googleMapsDirectionsApiKey.isEmpty) {
        throw Exception("Google Maps Directions API key is missing.");
      }

      // Fetch new directions from the Google Directions API
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleMapsDirectionsApiKey,
        request: PolylineRequest(
          headers: headers,
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.walking,
        ),
      );

      if (result.points.isEmpty) {
        throw Exception("No route points returned from Google Directions API.");
      }

      setState(() {
        final distanceMetres = result.totalDistanceValue ?? 0;
        final dashSpace = (distanceMetres > 0 ? distanceMetres : 500) / 50;

        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: result.points.map((point) => LatLng(point.latitude, point.longitude)).toList(),
            color: Theme.of(context).colorScheme.tertiary,
            width: 5,
            patterns: [PatternItem.dash(dashSpace), PatternItem.gap(dashSpace)],
          ),
        );

        _distanceToDestination = convertDistanceUnits(distanceMetres, preferredDistanceUnits);
      });
    } on SocketException catch (e) {
      debugPrint("Network error while fetching route: $e");
      _handlePolylineError("Network connection issue. Please try again.");
    } on HttpException catch (e) {
      debugPrint("HTTP error while fetching route: $e");
      _handlePolylineError("Server error retrieving route data.");
    } on FormatException catch (e) {
      debugPrint("Data format error: $e");
      _handlePolylineError("Unexpected data format from directions API.");
    } on Exception catch (e, stack) {
      debugPrint("Unexpected error fetching directions: $e\n$stack");
      _handlePolylineError("Failed to get route directions.");
    }
  }

  void _handlePolylineError(String message) {
    setState(() {
      _polylines.clear();
      _distanceToDestination = null;
      clearAllMarkers();
      addAllVisibleMarkers(false);
      _setMapCameraToFitMapMarkers();
      _navigationInProgress = false;
    });
    debugPrint(message);
    // Show a snackbar with the error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredMapOrientation', preferredMapOrientation.index);
    await prefs.setInt('preferredMapStyleType', preferredMapStyleType.index);
  }

  void _setMapCameraToFitMapMarkers() {
    // Set default LatLngs bounds
    // southwest
    double markerMinLat = listings.first.containsKey('latLng') ? stringToLatLng(listings.first['latLng']).latitude : 52.199174;
    double markerMinLong = listings.first.containsKey('latLng') ? stringToLatLng(listings.first['latLng']).longitude : 0.140929;
    // northeast
    double markerMaxLat = listings.first.containsKey('latLng') ? stringToLatLng(listings.first['latLng']).latitude : 52.199174;
    double markerMaxLong = listings.first.containsKey('latLng') ? stringToLatLng(listings.first['latLng']).longitude : 0.140929;

    if (listings.isNotEmpty) {
      for (var listing in listings) {
        LatLng markerLatLng = stringToLatLng(listing['latLng']);
        if (markerLatLng.latitude < markerMinLat) markerMinLat = markerLatLng.latitude;
        if (markerLatLng.latitude > markerMaxLat) markerMaxLat = markerLatLng.latitude;
        if (markerLatLng.longitude < markerMinLong) markerMinLong = markerLatLng.longitude;
        if (markerLatLng.longitude > markerMaxLong) markerMaxLong = markerLatLng.longitude;
      }
    }

    switch (preferredMapOrientation) {
      case MapOrientation.adaptive:
        _moveCameraToBoundsWithRotation(LatLng(markerMinLat, markerMinLong), LatLng(markerMaxLat, markerMaxLong), 25, 290);
        break;
      case MapOrientation.alwaysNorth:
        _moveCameraToBoundsWithRotation(LatLng(markerMinLat, markerMinLong), LatLng(markerMaxLat, markerMaxLong), 75, 0);
        break;
    }
  }

  void _setMapCameraToFitPolyline(Set<Polyline> polylines) {
    double polylineMinLat = polylines.first.points.first.latitude;
    double polylineMinLong = polylines.first.points.first.longitude;
    double polylineMaxLat = polylines.first.points.first.latitude;
    double polylineMaxLong = polylines.first.points.first.longitude;

    for (var polyline in polylines) {
      for (var point in polyline.points) {
        if (point.latitude < polylineMinLat) polylineMinLat = point.latitude;
        if (point.latitude > polylineMaxLat) polylineMaxLat = point.latitude;
        if (point.longitude < polylineMinLong) polylineMinLong = point.longitude;
        if (point.longitude > polylineMaxLong) polylineMaxLong = point.longitude;
      }
    }

    _moveCameraToBoundsWithRotation(LatLng(polylineMinLat, polylineMinLong), LatLng(polylineMaxLat, polylineMaxLong), 75, 0);
  }

  _moveCameraToBoundsWithRotation(LatLng southwestMin, LatLng northeastMax, double padding, double rotation) {
    double theZoom;

    if (mapWidth != null && mapHeight != null) {
      theZoom = zoomForBounds(southwestMin, northeastMax, Size(mapWidth!, mapHeight!), padding: padding);
    } else {
      theZoom = 15;
      debugPrint('No map areas size found so using default zoom of $theZoom');
    }

    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: southwestMin,
          northeast: northeastMax,
        ),
        padding, // Padding around the bounds
      ),
    );
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng((southwestMin.latitude + northeastMax.latitude) / 2, (southwestMin.longitude + northeastMax.longitude) / 2),
          zoom: theZoom,
          bearing: rotation,
        ),
      ),
    );
  }

  double _latRad(double lat) {
    final sinVal = sin(lat * pi / 180);
    final radX2 = log((1 + sinVal) / (1 - sinVal)) / 2;
    return max(min(radX2, pi), -pi) / 2;
  }

  double zoomForBounds(
    LatLng southwestMin,
    LatLng northeastMax,
    Size mapSize, {
    double padding = 0,
  }) {
    const worldDIM = 256.0;
    const zoomMax = 21.0;

    // Effective size after padding
    // The '4 / MediaQuery.of(context).devicePixelRatio)' adjusts the padding according to the device
    final usableWidth = mapSize.width - (2 * padding * 4 / MediaQuery.of(context).devicePixelRatio);
    final usableHeight = mapSize.height - (2 * padding * 4 / MediaQuery.of(context).devicePixelRatio);

    if (usableWidth <= 0 || usableHeight <= 0) return 0;

    final latFraction = (_latRad(northeastMax.latitude) - _latRad(southwestMin.latitude)) / pi;

    final centerLat = (northeastMax.latitude + southwestMin.latitude) / 2;
    final lngDiff = northeastMax.longitude - southwestMin.longitude;
    final lngFraction = (lngDiff < 0 ? lngDiff + 360 : lngDiff) / 360;

    // scale by cos(latitude) to account for Mercator
    final adjustedLngFraction = lngFraction * cos(centerLat * pi / 180);

    final lngZoom = log(usableWidth / worldDIM / adjustedLngFraction) / ln2;

    final latZoom = log(usableHeight / worldDIM / latFraction) / ln2;

    final zoom = min(latZoom, lngZoom);
    return min(zoom, zoomMax);
  }

  Future<void> refreshListings() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      listings = await fetchListings(http.Client());
      addAllVisibleMarkers(false);
      establishLocation();
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchListings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              textAlign: TextAlign.center,
              style: TextStyle(
                backgroundColor: Theme.of(context).colorScheme.error,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          );
        }

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Unable to retrieve listings",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                isRefreshing
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: refreshListings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Listings'),
                      ),
              ],
            ),
          );
        }

        switch (preferredMapOrientation) {
          case MapOrientation.adaptive:
            _mapBearing = 290;
            _compassBearing = 90;
            break;
          case MapOrientation.alwaysNorth:
            _mapBearing = 0;
            _compassBearing = 0;
            break;
        }

        switch (preferredMapStyleType) {
          case MapStyleType.normal:
            mapType = MapType.normal;
            break;
          case MapStyleType.hybrid:
            mapType = MapType.hybrid;
            break;
        }

        return Scaffold(
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  mapWidth = constraints.maxWidth;
                  mapHeight = constraints.maxHeight;
                  return GoogleMap(
                    // TODO: Possible deprecation of styles in March 2025 (See: https://www.atlist.com/blog/json-map-styles-will-stop-working-march-2025)
                    style: mapStyle,
                    mapType: mapType,
                    rotateGesturesEnabled: false,
                    compassEnabled: false,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapToolbarEnabled: false,
                    onMapCreated: (GoogleMapController controller) {
                      _controller = controller;
                      if (listings.isNotEmpty) {
                        // We should have listings by this point so set the camera to their bounds
                        _setMapCameraToFitMapMarkers();
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: const LatLng(52.199174, 0.140929),
                      zoom: 14.1,
                      bearing: _mapBearing,
                    ),
                    onCameraMove: (CameraPosition position) {
                      setState(() {
                        switch (preferredMapOrientation) {
                          case MapOrientation.adaptive:
                            _compassBearing = 90;
                            break;
                          case MapOrientation.alwaysNorth:
                            _compassBearing = 0;
                            break;
                        }
                      });
                    },
                    markers: markers.values.toSet(),
                    polylines: _polylines,
                  );
                },
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_navigationInProgress == true)
                      FloatingActionButton(
                        heroTag: 'cancelBtn',
                        shape: const CircleBorder(),
                        mini: true,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _positionStream?.cancel();
                            _polylines.clear();
                            _distanceToDestination = null;
                            clearAllMarkers();
                            addAllVisibleMarkers(false);
                            _setMapCameraToFitMapMarkers();
                            _navigationInProgress = false;
                          });
                        },
                        child: Icon(
                          Icons.cancel,
                          size: 24,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    if (_navigationInProgress == false)
                      FloatingActionButton(
                        heroTag: 'homeBtn',
                        shape: const CircleBorder(),
                        mini: true,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _setMapCameraToFitMapMarkers();
                        },
                        child: Icon(
                          Icons.home,
                          size: 24,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    FloatingActionButton(
                      heroTag: 'mapTypeBtn',
                      shape: const CircleBorder(),
                      mini: true,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (mapType == MapType.normal) {
                            mapType = MapType.hybrid;
                            _layersIcon = Icons.map;
                            preferredMapStyleType = MapStyleType.hybrid;
                            _saveSettings();
                          } else {
                            mapType = MapType.normal;
                            _layersIcon = Icons.satellite_alt;
                            preferredMapStyleType = MapStyleType.normal;
                            _saveSettings();
                          }
                        });
                      },
                      child: Icon(
                        _layersIcon,
                        size: 24,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    if (_navigationInProgress == false)
                      AnimatedRotation(
                        turns: _compassBearing / 360.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: FloatingActionButton(
                          heroTag: 'mapBearingBtn',
                          shape: const CircleBorder(),
                          mini: true,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              preferredMapOrientation =
                                  (preferredMapOrientation == MapOrientation.adaptive) ? MapOrientation.alwaysNorth : MapOrientation.adaptive;
                              _saveSettings();
                            });
                            _setMapCameraToFitMapMarkers();
                          },
                          child: const Icon(Icons.assistant_navigation),
                        ),
                      )
                  ],
                ),
              ),
              if (_distanceToDestination != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: FloatingActionButton.extended(
                      heroTag: 'navigationBtn',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _setMapCameraToFitPolyline(_polylines);
                      },
                      icon: const Icon(Icons.directions),
                      label: Text(
                        _distanceToDestination!,
                        style: TextStyle(fontSize: 24, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
