import 'dart:async';
import 'dart:io';
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
import 'package:mill_road_winter_fair_app/listings_info_sheet.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/string_to_latlng.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

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
  late List<MarkerId> _foodMarkerIds;
  late List<MarkerId> _stallsMarkerIds;
  late List<MarkerId> _musicMarkerIds;
  late List<MarkerId> _eventMarkerIds;
  late List<MarkerId> _serviceMarkerIds;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{}; // Current display of visible map markers
  Map<MarkerId, Marker> allMarkers = <MarkerId, Marker>{}; // Cache of all markers, visible or not
  final Set<Polyline> _polylines = {}; // For displaying the route polyline
  late PolylinePoints _polylinePoints; // For decoding points
  Map<String, BitmapDescriptor> bitmapDescriptors = <String, BitmapDescriptor>{};  // Cache of custom BitmapDescriptors
  bool _navigationInProgress = false;
  String? _distanceToDestination;
  StreamSubscription<Position>? _positionStream;
  LatLng? _destination; // To store the destination
  GoogleMapController? _controller;
  MapType mapType = MapType.normal;
  IconData _layersIcon = Icons.satellite_alt;
  bool isRefreshing = false;
  // Declare default filters
  final Map<String, bool> filterSettings = {
    'Food': true,
    'Stalls': true,
    'Music': true,
    'Events': true,
    'Services': true,
  };
 final Map<String, bool> listingTypes = {
    'Food': true,
    'Shopping': true,
    'Music': true,
    'Event': true,
    'Service': true,
  };

  @override
  void initState() {
    _polylinePoints = PolylinePoints();
    _fetchListings = fetchExistingListings(http.Client());
    setMarkerLists();
    addAllMarkers(false);
    establishLocation();
    super.initState();
  }

 void addAllMarkers(bool onTest) async {
    if (bitmapDescriptors.length == 0) {
      bool gotBitmaps = await createAllMarkerBitmaps(false);
    }
    for (var listing in listings) {
      addMarker(listing, onTest);
    }
    allMarkers = Map.from(markers);
  }

  Future<bool> createAllMarkerBitmaps(bool onTest) async {
    for (var listingType in listingTypes.keys) {
      BitmapDescriptor newBitmapDescriptor = await getColoredMarker(listingType, getCategoryColor(selectedThemeKey, listingType));
      bitmapDescriptors[listingType] = newBitmapDescriptor;
    }
    if (bitmapDescriptors.length == 0) {
      debugPrint('Error: created zero bitmap descriptors');
      return false;
    } else {
      return true;
    }
  }

  void updateMarkerVisibility(List<MarkerId> idList, bool visibleState) {
    // now removes and re-adds markers to work around iOS not keeping pace with many show/hides, causing memory errors
    final updated = Map<MarkerId, Marker>.from(markers);
    for (var id in idList) {
      if (visibleState) {
        // Show again → re-add original marker (from a cache of all markers)
        final original = allMarkers[id];
        if (original != null) {
          updated[id] = original;
        }
      } else {
        // Hide → remove completely
        updated.remove(id);
      }
    }
    // batch update state
    setState(() {
      markers = updated;
    });
  }

  void setMarkerLists() {
    // Reset marker lists
    _foodMarkerIds = [];
    _stallsMarkerIds = [];
    _musicMarkerIds = [];
    _eventMarkerIds = [];
    _serviceMarkerIds = [];

    final allListings = listings as List;
    for (var listing in allListings) {
      // Assign markerIds to maps for filtering
      if (listing['primaryType'] == "Food") {
        _foodMarkerIds.add(MarkerId(listing['id'].toString()));
      } else if (listing['primaryType'] == "Shopping") {
        _stallsMarkerIds.add(MarkerId(listing['id'].toString()));
      } else if (listing['primaryType'] == "Music") {
        _musicMarkerIds.add(MarkerId(listing['id'].toString()));
      } else if (listing['primaryType'] == "Event") {
        _eventMarkerIds.add(MarkerId(listing['id'].toString()));
      } else if (listing['primaryType'] == "Service") {
        _serviceMarkerIds.add(MarkerId(listing['id'].toString()));
      }
    }
  }

  void addMarker(listing, bool onTest) async {
    LatLng destinationLatLng = stringToLatLng(listing['latLng']);
    MarkerId markerId = MarkerId(listing['id'].toString());
    Color color = getCategoryColor(selectedThemeKey, listing['primaryType']);
    late BitmapDescriptor customMarker;
    if (onTest == false) {
      customMarker = bitmapDescriptors[listing['primaryType']] ?? BitmapDescriptor.defaultMarker;
      // debugPrint('Got bitmap descriptor for ${listing['primaryType']} from cache of size '+bitmapDescriptors.length.toString()+': $customMarker');
    } else {
      double hue = HSVColor.fromColor(color).hue;
      customMarker = BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    Marker newMarker = Marker(
      markerId: markerId,
      position: destinationLatLng,
      icon: customMarker,
      visible: true,
      onTap: () {
        // Update user's location
        establishLocation();
        int approximateDistanceMetres = asTheCrowFlies(currentLatLng, destinationLatLng);
        // Show bottom sheet with listing information
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return ListingInfoSheet(
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

  //The Remove All filters button seems to prefer using this function rather than doing it's own setState
  void clearAllMarkers() {
    setState(() {
      markers.clear();
    });
  }

  void showFilterMenu() {
    showModalBottomSheet(
      scrollControlDisabledMaxHeightRatio: 0.8,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      "Filter Map Pins",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    )
                  ]),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Food'),
                    title: const Text("Food"),
                    value: filterSettings["Food"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Food"] = value!;
                      });
                      final idList = _foodMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Shopping'),
                    title: const Text("Stalls"),
                    value: filterSettings["Stalls"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Stalls"] = value!;
                      });
                      final idList = _stallsMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Music'),
                    title: const Text("Music"),
                    value: filterSettings["Music"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Music"] = value!;
                      });
                      final idList = _musicMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Event'),
                    title: const Text("Events"),
                    value: filterSettings["Events"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Events"] = value!;
                      });
                      final idList = _eventMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Service'),
                    title: const Text("Services"),
                    value: filterSettings["Services"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Services"] = value!;
                      });
                      final idList = _serviceMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            filterSettings.forEach((key, _) {
                              filterSettings[key] = true;
                            });
                          });
                          final idList = _foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds;
                          updateMarkerVisibility(idList, true);
                        },
                        icon: const Icon(Icons.filter_alt),
                        label: const Text('Show All'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            filterSettings.forEach((key, _) {
                              filterSettings[key] = false;
                            });
                          });
                          final idList = _foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds;
                          updateMarkerVisibility(idList, false);
                        },
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Hide All'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> getDirections(String id, LatLng destination, bool navigatorPop) async {
    // Pop the navigator if told to
    if (navigatorPop == true) {
      Navigator.pop(context);
    }

    // Clear any existing polylines
    setState(() {
      _polylines.clear(); // Clear any existing polylines
      final idList = _foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds;
      updateMarkerVisibility(idList, false); // Hide any existing markers
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

    // Re-add destination marker
    MarkerId markerId = MarkerId(id.toString());
    List<MarkerId> destinationMarkerIds = [];
    destinationMarkerIds.add(markerId);
    updateMarkerVisibility(destinationMarkerIds, true);

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

    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: result.points.map((point) => LatLng(point.latitude, point.longitude)).toList(),
          color: Theme.of(context).colorScheme.tertiary,
          width: 5,
          patterns: <PatternItem>[PatternItem.dash(10), PatternItem.gap(10)],
        ));
        final distanceMetres = result.totalDistanceValue;
        _distanceToDestination = convertDistanceUnits(distanceMetres!, preferredDistanceUnits);
      });
    }
  }

  void _resetMapCamera() {
    _setMapCameraToFitMapMarkers();
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

    _moveCameraToBounds(LatLng(markerMinLat, markerMinLong), LatLng(markerMaxLat, markerMaxLong), 25);
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

    _moveCameraToBounds(LatLng(polylineMinLat, polylineMinLong), LatLng(polylineMaxLat, polylineMaxLong), 75);
  }

  _moveCameraToBounds(LatLng southwestMin, LatLng northeastMax, double padding) {
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(52.199174, 0.140929),
          zoom: 15,
          bearing: 290,
        ),
      ),
    );
    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: southwestMin,
          northeast: northeastMax,
        ),
        padding, // Padding around the bounds
      ),
    );
}

  Future<void> refreshListings() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      listings = await fetchListings(http.Client());
      setMarkerLists();
      addAllMarkers(false);
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
          ));
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

        return Scaffold(
          body: GoogleMap(
            // TODO: Possible deprecation of styles in March 2025 (See: https://www.atlist.com/blog/json-map-styles-will-stop-working-march-2025)
            style: mapStyle,
            mapType: mapType,
            rotateGesturesEnabled: true,
            compassEnabled: true,
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
            initialCameraPosition: const CameraPosition(
              target: LatLng(52.199174, 0.140929),
              zoom: 15,
            ),
            markers: markers.values.toSet(),
            polylines: _polylines,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
          floatingActionButton: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_navigationInProgress == true)
                            IconButton.filled(
                              onPressed: () {
                                setState(() {
                                  _positionStream?.cancel();
                                  _polylines.clear();
                                  _distanceToDestination = null;
                                  final idList = _foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds;
                                  updateMarkerVisibility(idList, true);
                                  _navigationInProgress = false;
                                });
                              },
                              icon: Icon(
                                Icons.cancel,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                        ],
                      ),
                      Row(
                        children: [
                          if (_navigationInProgress == false)
                            IconButton.filled(
                              onPressed: () {
                                _resetMapCamera();
                                if (filterSettings['Food'] == false &&
                                    filterSettings['Stalls'] == false &&
                                    filterSettings['Music'] == false &&
                                    filterSettings['Events'] == false &&
                                    filterSettings['Services'] == false) {
                                  final idList = _foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds;
                                  setState(() {
                                    filterSettings['Food'] = true;
                                    filterSettings['Stalls'] = true;
                                    filterSettings['Music'] = true;
                                    filterSettings['Events'] = true;
                                    filterSettings['Services'] = true;
                                    updateMarkerVisibility(idList, true);
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.home,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          if (_navigationInProgress == false)
                            IconButton.filled(
                              onPressed: () {
                                showFilterMenu();
                                setMarkerLists();
                              },
                              icon: Icon(
                                Icons.filter_alt,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton.filled(
                            onPressed: () {
                              setState(() {
                                if (mapType == MapType.normal) {
                                  mapType = MapType.hybrid;
                                  _layersIcon = Icons.map;
                                } else {
                                  mapType = MapType.normal;
                                  _layersIcon = Icons.satellite_alt;
                                }
                              });
                            },
                            icon: Icon(
                              _layersIcon,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_distanceToDestination != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                _setMapCameraToFitPolyline(_polylines);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                              icon: Icon(Icons.directions, color: Theme.of(context).colorScheme.onPrimary),
                              label: Text(
                                _distanceToDestination!,
                                style: TextStyle(fontSize: 28, color: Theme.of(context).colorScheme.onPrimary),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Column(), // Dummy column to help flex with centring distance button
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
