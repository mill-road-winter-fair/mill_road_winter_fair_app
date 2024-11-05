import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/get_current_location.dart';
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
  MapType _mapType = MapType.normal;
  IconData _layersIcon = Icons.satellite_alt;

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();
    fetchListings();
  }

  fetchListings() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/listings'));
    if (response.statusCode == 200) {
      final listings = json.decode(response.body);
      for (var listing in listings) {
        LatLng? coordinates =
            await getCoordinatesFromPlusCode(listing['plusCode'], googleApiKey);

        if (coordinates != null) {
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(listing['id'].toString()),
                position: coordinates,
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
                        onGetDirections: () => getDirections(coordinates),
                      );
                    },
                  );
                },
              ),
            );
          });
        }
      }
    }
  }

  Future<void> getDirections(LatLng destination) async {
    // Get the user's current location
    Position position = await getCurrentLocation();
    LatLng origin = LatLng(position.latitude, position.longitude);

    // Fetch directions from Google Directions API
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleApiKey,
      request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.walking),
    );

    // Check if route points were fetched successfully
    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.clear(); // Clear any existing route
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: const Color.fromRGBO(204, 51, 51, 1.0),
          width: 5,
        ));
      });
    } else {
      throw Exception("Failed to fetch directions");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GoogleMap(
          mapType: _mapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (GoogleMapController controller) {},
          initialCameraPosition: const CameraPosition(
            target: LatLng(
                52.199212, 0.139342),
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
                                _polylines.clear();
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
