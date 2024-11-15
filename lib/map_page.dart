import 'dart:convert';
import 'dart:async'; // For StreamSubscription
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheet.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/plus_code_handlers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

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
  String? distanceToDestination;
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation; // To store the user's current location
  LatLng? _destination; // To store the destination
  GoogleMapController? _controller; // Declare _controller here
  MapType mapType = MapType.normal;
  IconData _layersIcon = Icons.satellite_alt;
  // Declare default filters
  final Map<String, bool> filterSettings = {
    'Vendor_Food': true,
    'Vendor_Retail': true,
    'Performer_*': true,
    'Event_*': true,
    'Service_*': true,
  };

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();
    fetchListings();
  }

  Future<void> fetchListings() async {
    setState(() {
      markers.clear();
    });
    final response = await http.get(Uri.parse('$mrwfApi/listings'));
    if (response.statusCode == 200) {
      final listings = json.decode(response.body);
      for (var listing in listings) {
        addMarker(listing, http.Client());
      }
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

    LatLng? coordinates = await getCoordinatesFromPlusCode(listing['plusCode'], googleApiKey, client);

    MarkerId markerId = MarkerId(listing['id'].toString());

    if (coordinates != null) {
      double hue = getMarkerColorHue(listing['primaryType']);

      Marker newMarker = Marker(
        markerId: markerId,
        position: coordinates,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue), // Set marker color
        visible: true,
        onTap: () {
          // Show bottom sheet with listing information
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return ListingInfoSheet(
                title: listing['displayName'],
                categories: listing['secondaryType'] + ' • ' + listing['tertiaryType'],
                openingTimes: listing['startTime'] + ' - ' + listing['endTime'],
                phoneNumber: listing['phone'],
                website: listing['website'],
                onGetDirections: () => getDirections(listing['id'], coordinates),
              );
            },
          );
        },
      );

      setState(() {
        markers[markerId] = newMarker;
      });
    }
  }

  double getMarkerColorHue(String primaryType) {
    if (primaryType == "Food") {
      Color color = const Color.fromRGBO(204, 110, 51, 1.0);
      double hue = HSVColor.fromColor(color).hue;
      return hue;
    } else if (primaryType == "Shopping") {
      Color color = const Color.fromRGBO(204, 51, 51, 1);
      double hue = HSVColor.fromColor(color).hue;
      return hue;
    } else if (primaryType == "Music") {
      Color color = const Color.fromRGBO(204, 51, 120, 1.0);
      double hue = HSVColor.fromColor(color).hue;
      return hue;
    } else if (primaryType == "Event") {
      Color color = const Color.fromRGBO(204, 161, 51, 1.0);
      double hue = HSVColor.fromColor(color).hue;
      return hue;
    } else if (primaryType == "Service") {
      Color color = const Color.fromRGBO(153, 0, 255, 1.0);
      double hue = HSVColor.fromColor(color).hue;
      return hue;
    }

    //Default colour
    Color color = const Color.fromRGBO(255, 255, 255, 1.0);
    double hue = HSVColor.fromColor(color).hue;
    return hue;
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
                      activeColor: const Color.fromRGBO(204, 110, 51, 1.0),
                      title: const Text("Food"),
                      value: filterSettings["Vendor_Food"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Vendor_Food"] = value!;
                        });
                        final idList = foodMarkerIds;
                        updateMarkerVisibility(idList, value!);
                      },
                    ),
                    CheckboxListTile(
                      activeColor: const Color.fromRGBO(204, 51, 51, 1.0),
                      title: const Text("Shopping"),
                      value: filterSettings["Vendor_Retail"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Vendor_Retail"] = value!;
                        });
                        final idList = shoppingMarkerIds;
                        updateMarkerVisibility(idList, value!);
                      },
                    ),
                    CheckboxListTile(
                      activeColor: const Color.fromRGBO(204, 51, 120, 1.0),
                      title: const Text("Music"),
                      value: filterSettings["Performer_*"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Performer_*"] = value!;
                        });
                        final idList = musicMarkerIds;
                        updateMarkerVisibility(idList, value!);
                      },
                    ),
                    CheckboxListTile(
                      activeColor: const Color.fromRGBO(204, 161, 51, 1.0),
                      title: const Text("Events"),
                      value: filterSettings["Event_*"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Event_*"] = value!;
                        });
                        final idList = eventMarkerIds;
                        updateMarkerVisibility(idList, value!);
                      },
                    ),
                    CheckboxListTile(
                      activeColor: const Color.fromRGBO(153, 0, 255, 1.0),
                      title: const Text("Services"),
                      value: filterSettings["Service_*"],
                      onChanged: (value) {
                        setState(() {
                          filterSettings["Service_*"] = value!;
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

  Future<void> getDirections(int id, LatLng destination) async {
    // Clear any existing polylines
    setState(() {
      _polylines.clear(); // Clear any existing polylines
      final idList = foodMarkerIds + shoppingMarkerIds + musicMarkerIds + eventMarkerIds + serviceMarkerIds;
      updateMarkerVisibility(idList, false); // Hide any existing markers
    });

    // Get the user's current location
    Position position = await getCurrentLocation();
    LatLng origin = LatLng(position.latitude, position.longitude);
    await updatePolyline(origin, destination);
    // Set the camera position once, at the beginning of the navigation
    _setMapFitToPolyline(_polylines);

    // Start location updates
    await startLocationUpdates(destination);

    // Re-add destination marker
    MarkerId markerId = MarkerId(id.toString());
    List<MarkerId> destinationMarkerIds = [];
    destinationMarkerIds.add(markerId);
    updateMarkerVisibility(destinationMarkerIds, true);
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
      _currentLocation = LatLng(position.latitude, position.longitude);

      // If a destination is set, get new directions and update the polyline
      if (_destination != null) {
        await updatePolyline(_currentLocation!, _destination!);
      }
    });
  }

  Future<void> updatePolyline(LatLng origin, LatLng destination) async {
    // Fetch new directions from the Google Directions API
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleApiKey,
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
          color: const Color.fromRGBO(204, 51, 51, 1.0),
          width: 5,
          patterns: <PatternItem>[PatternItem.dot, PatternItem.gap(10)],
        ));
        final distanceMetres = result.totalDistanceValue;
        if (distanceMetres! <= 999) {
          distanceToDestination = '$distanceMetres m';
        } else {
          final distanceKilometres = (distanceMetres / 1000);
          distanceToDestination = '$distanceKilometres km';
        }
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
    return Scaffold(
        body: GoogleMap(
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
        floatingActionButton: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton.filled(
                        onPressed: () {
                          showFilterMenu();
                        },
                        icon: const Icon(
                          Icons.filter_alt,
                          color: Color.fromRGBO(255, 255, 255, 1.0),
                        )),
                    if (distanceToDestination != null)
                      ElevatedButton.icon(
                          onPressed: () {
                            _setMapFitToPolyline(_polylines);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(204, 51, 51, 1)),
                          icon: const Icon(Icons.directions, color: Color.fromRGBO(255, 255, 255, 1.0)),
                          label: Text(
                            distanceToDestination!,
                            style: const TextStyle(fontSize: 28, color: Colors.white),
                          ))
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
                          color: const Color.fromRGBO(255, 255, 255, 1.0),
                        ))
                  ],
                ),
                Row(
                  children: [
                    if (_polylines.isNotEmpty)
                      IconButton.filled(
                          onPressed: () {
                            setState(() {
                              _positionStream?.cancel();
                              _polylines.clear();
                              final idList = foodMarkerIds + shoppingMarkerIds + musicMarkerIds + eventMarkerIds + serviceMarkerIds;
                              updateMarkerVisibility(idList, true);
                            });
                          },
                          icon: const Icon(
                            Icons.wrong_location,
                            color: Color.fromRGBO(255, 255, 255, 1.0),
                          ))
                  ],
                )
              ],
            )));
  }
}
