import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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
  late http.Client client;
  List<MarkerId> foodMarkerIds = [];
  List<MarkerId> shoppingMarkerIds = [];
  List<MarkerId> musicMarkerIds = [];
  List<MarkerId> eventMarkerIds = [];
  List<MarkerId> serviceMarkerIds = [];
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{}; // For displaying the map markers
  final Set<Polyline> _polylines = {}; // For displaying the route polyline
  late PolylinePoints polylinePoints; // For decoding points
  bool navigationInProgress = false;
  String? distanceToDestination;
  StreamSubscription<Position>? _positionStream;
  LatLng? _destination; // To store the destination
  GoogleMapController? _controller; // Declare _controller here
  MapType mapType = MapType.normal;
  IconData _layersIcon = Icons.satellite_alt;
  // Declare default filters
  final Map<String, bool> filterSettings = {
    'Food': true,
    'Shopping': true,
    'Music': true,
    'Events': true,
    'Services': true,
  };

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();
    establishLocation();
  }

  void addAllMarkers() {
    final allListings = listings as List;
    for (var listing in allListings) {
      addMarker(listing, http.Client());
    }
  }

  void updateMarkerVisibility(List<MarkerId> idList, bool visibleState) {
    for (var id in idList) {
      final currentMarker = markers.values.toList().firstWhere((item) => item.markerId == id);

      Marker updatedMarker = Marker(
        markerId: id,
        position: currentMarker.position,
        icon: currentMarker.icon,
        visible: visibleState,
        onTap: currentMarker.onTap,
      );

      setState(() {
        markers[id] = updatedMarker;
      });
    }
  }

  addMarker(listing, client) async {
    // Option to use a mock function (for tests)
    client ??= http.Client();

    // Assign markerIds to maps for filtering
    if (listing['primaryType'] == "Food") {
      foodMarkerIds.add(MarkerId(listing['id'].toString()));
    } else if (listing['primaryType'] == "Shopping") {
      shoppingMarkerIds.add(MarkerId(listing['id'].toString()));
    } else if (listing['primaryType'] == "Music") {
      musicMarkerIds.add(MarkerId(listing['id'].toString()));
    } else if (listing['primaryType'] == "Event") {
      eventMarkerIds.add(MarkerId(listing['id'].toString()));
    } else if (listing['primaryType'] == "Service") {
      serviceMarkerIds.add(MarkerId(listing['id'].toString()));
    }

    LatLng destinationLatLng = stringToLatLng(listing['latLng']);

    MarkerId markerId = MarkerId(listing['id'].toString());

    Color color = getMarkerColor(selectedThemeKey, listing['primaryType']);
    double hue = HSVColor.fromColor(color).hue;

    Marker newMarker = Marker(
      markerId: markerId,
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(hue), // Set marker color
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
              categories: listing['secondaryType'] + ' • ' + listing['tertiaryType'],
              openingTimes: listing['startTime'] + ' - ' + listing['endTime'],
              approxDistance: 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}',
              phoneNumber: listing['phone'],
              website: listing['website'],
              onGetDirections: () => getDirections(listing['id'], destinationLatLng, true),
            );
          },
        );
      },
    );

    markers[markerId] = newMarker;
  }

  //The Remove All filters button seems to prefer using this function rather than doing it's own setState
  void clearAllMarkers() {
    setState(() {
      markers.clear();
    });
  }

  void showFilterMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
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
                      activeColor: getMarkerColor(selectedThemeKey, 'Food'),
                      title: const Text("Food"),
                      value: filterSettings["Food"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Food"] = value!;
                        });
                        final idList = foodMarkerIds;
                        updateMarkerVisibility(idList, value!);
                      },
                    ),
                    CheckboxListTile(
                      activeColor: getMarkerColor(selectedThemeKey, 'Shopping'),
                      title: const Text("Shopping"),
                      value: filterSettings["Shopping"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Shopping"] = value!;
                        });
                        final idList = shoppingMarkerIds;
                        updateMarkerVisibility(idList, value!);
                      },
                    ),
                    CheckboxListTile(
                      activeColor: getMarkerColor(selectedThemeKey, 'Music'),
                      title: const Text("Music"),
                      value: filterSettings["Music"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Music"] = value!;
                        });
                        final idList = musicMarkerIds;
                        updateMarkerVisibility(idList, value!);
                      },
                    ),
                    CheckboxListTile(
                      activeColor: getMarkerColor(selectedThemeKey, 'Event'),
                      title: const Text("Events"),
                      value: filterSettings["Events"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Events"] = value!;
                        });
                        final idList = eventMarkerIds;
                        updateMarkerVisibility(idList, value!);
                      },
                    ),
                    CheckboxListTile(
                      activeColor: getMarkerColor(selectedThemeKey, 'Service'),
                      title: const Text("Services"),
                      value: filterSettings["Services"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Services"] = value!;
                        });
                        final idList = serviceMarkerIds;
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
                            final idList = foodMarkerIds + shoppingMarkerIds + musicMarkerIds + eventMarkerIds + serviceMarkerIds;
                            updateMarkerVisibility(idList, true);
                            Navigator.pop(context);
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
                            final idList = foodMarkerIds + shoppingMarkerIds + musicMarkerIds + eventMarkerIds + serviceMarkerIds;
                            updateMarkerVisibility(idList, false);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Hide All'),
                        ),
                      ],
                    ),
                  ],
                )));
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
      final idList = foodMarkerIds + shoppingMarkerIds + musicMarkerIds + eventMarkerIds + serviceMarkerIds;
      updateMarkerVisibility(idList, false); // Hide any existing markers
    });

    // If user has location tracking enabled
    if (currentLatLng != null) {
      // Get the user's current location
      Position position = await getCurrentPosition();
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      await updatePolyline(currentLatLng, destination);
      // Set the camera position once, at the beginning of the navigation
      _setMapFitToPolyline(_polylines);

      // Start location updates
      await startLocationUpdates(destination);
    }

    // Re-add destination marker
    MarkerId markerId = MarkerId(id.toString());
    List<MarkerId> destinationMarkerIds = [];
    destinationMarkerIds.add(markerId);
    updateMarkerVisibility(destinationMarkerIds, true);

    // Set navigation as in progress
    navigationInProgress = true;
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
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
    String googleMapsAndSheetsApiKey = dotenv.env['GOOGLE_MAPS_AND_SHEETS_API_KEY'] ?? '';

    // Fetch new directions from the Google Directions API
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleMapsAndSheetsApiKey,
      request: PolylineRequest(
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
          // TODO: Update the route line colour if we start using custom maps
          color: const Color.fromRGBO(204, 51, 51, 1.0),
          width: 5,
          patterns: <PatternItem>[PatternItem.dot, PatternItem.gap(10)],
        ));
        final distanceMetres = result.totalDistanceValue;
        distanceToDestination = convertDistanceUnits(distanceMetres!, preferredDistanceUnits);
      });
    }
  }

  void _setMapFitToPolyline(Set<Polyline> polylines) {
    double minLat = polylines.first.points.first.latitude;
    double minLong = polylines.first.points.first.longitude;
    double maxLat = polylines.first.points.first.latitude;
    double maxLong = polylines.first.points.first.longitude;

    for (var polyline in polylines) {
      for (var point in polyline.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLong) minLong = point.longitude;
        if (point.longitude > maxLong) maxLong = point.longitude;
      }
    }

    _controller?.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLong),
          northeast: LatLng(maxLat, maxLong),
        ),
        75, // Padding around the bounds
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fetchExistingListings(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error fetching listings"));
          } else {
            addAllMarkers();
            return Scaffold(
              body: GoogleMap(
                // TODO: Possible deprecation of styles in March 2025 (See: https://www.atlist.com/blog/json-map-styles-will-stop-working-march-2025)
                style: mapStyle,
                mapType: mapType,
                rotateGesturesEnabled: false,
                compassEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapToolbarEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _controller = controller; // Assign the controller here
                },
                initialCameraPosition: const CameraPosition(
                  target: LatLng(52.199174, 0.140929),
                  zoom: 14.3,
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
                              IconButton.filled(
                                onPressed: () {
                                  showFilterMenu();
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
                                      mapType = MapType.satellite;
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
                          Row(
                            children: [
                              if (navigationInProgress == true)
                                IconButton.filled(
                                    onPressed: () {
                                      setState(() {
                                        _positionStream?.cancel();
                                        _polylines.clear();
                                        distanceToDestination = null;
                                        final idList = foodMarkerIds + shoppingMarkerIds + musicMarkerIds + eventMarkerIds + serviceMarkerIds;
                                        updateMarkerVisibility(idList, true);
                                        navigationInProgress = false;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.wrong_location,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ))
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
                              if (distanceToDestination != null)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _setMapFitToPolyline(_polylines);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                                  icon: Icon(Icons.directions, color: Theme.of(context).colorScheme.onPrimary),
                                  label: Text(
                                    distanceToDestination!,
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
          }
        });
  }
}
