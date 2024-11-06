import 'dart:convert';
import 'dart:async'; // For StreamSubscription
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/listings_info_sheet.dart';
import 'package:mill_road_winter_fair_app/plus_code_handlers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'main.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {}; // For displaying the route polyline
  late PolylinePoints polylinePoints; // For decoding points
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation; // To store the user's current location
  LatLng? _destination; // To store the destination
  GoogleMapController? _controller; // Declare _controller here
  MapType _mapType = MapType.normal;
  IconData _layersIcon = Icons.satellite_alt;

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();
    fetchListings();
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
          points: result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: const Color.fromRGBO(204, 51, 51, 1.0),
          width: 5,
          patterns: <PatternItem>[PatternItem.dot, PatternItem.gap(10)],
        ));
      });

      // Adjust the map camera to fit the polyline
      // TODO: Might need to change this later as it will adjust the camera every time the device location updates
      _setMapFitToPolyline(_polylines);
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

  addMarker(listing) async {
    LatLng? coordinates =
        await getCoordinatesFromPlusCode(listing['plusCode'], googleApiKey);

    if (coordinates != null) {
      setState(() {
        Color markerColor =
            getMarkerColor(listing['primaryType'], listing['secondaryType']);
        _markers.add(
          Marker(
            markerId: MarkerId(listing['id'].toString()),
            position: coordinates,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              HSVColor.fromColor(markerColor).hue), // Set marker color
            onTap: () {
              // Show bottom sheet with listing information
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return ListingInfoSheet(
                    title: listing['displayName'],
                    categories: listing['secondaryType'] +
                        ' • ' +
                        listing['tertiaryType'],
                    openingTimes:
                        listing['startTime'] + ' - ' + listing['endTime'],
                    phoneNumber: listing['phone'],
                    website: listing['website'],
                    onGetDirections: () =>
                        getDirections(listing['id'], coordinates),
                  );
                },
              );
            },
          ),
        );
      });
    }
  }

  Color getMarkerColor(String primaryType, String secondaryType) {
    if (primaryType == "Vendor" && secondaryType == "Food") {
      return const Color.fromRGBO(204, 110, 51, 1.0);
    } else if (primaryType == "Vendor" && secondaryType == "Retail") {
      return const Color.fromRGBO(204, 51, 51, 1);
    } else if (primaryType == "Performer") {
      return const Color.fromRGBO(204, 51, 120, 1.0);
    } else if (primaryType == "Event") {
      return const Color.fromRGBO(204, 161, 51, 1.0);
    } else if (primaryType == "Service") {
      return const Color.fromRGBO(120, 120, 120, 1.0);
    }

    //Default colour
    return Colors.white;
  }

  fetchListings() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/listings'));
    if (response.statusCode == 200) {
      final listings = json.decode(response.body);
      for (var listing in listings) {
        addMarker(listing);
      }
    }
  }

  Future<void> getDirections(int id, LatLng destination) async {
    // Clear any existing polylines
    setState(() {
      _polylines.clear(); // Clear any existing polylines
      _markers.clear(); // Clear any existing markers
    });

    // Start location updates
    await startLocationUpdates(destination);

    // Re-add destination marker
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/listings'));
    if (response.statusCode == 200) {
      final listings = json.decode(response.body);
      //TODO: This is needlessly iterating through all listings, once we've added params to the backend we can get just the necessary listing
      for (var listing in listings) {
        if (listing['id'] == id) {
          addMarker(listing);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GoogleMap(
          mapType: _mapType,
          rotateGesturesEnabled: false,
          compassEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _controller = controller; // Assign the controller here
          },
          initialCameraPosition: const CameraPosition(
            target: LatLng(52.199212, 0.139342),
            zoom: 15,
          ),
          markers: _markers,
          polylines: _polylines,
        ),
        floatingActionButton: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton.filled(
                        onPressed: () {
                          setState(() {
                            if (_mapType == MapType.normal) {
                              _mapType = MapType.satellite;
                              _layersIcon = Icons.map;
                            } else {
                              _mapType = MapType.normal;
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
                              _markers.clear();
                              fetchListings();
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
