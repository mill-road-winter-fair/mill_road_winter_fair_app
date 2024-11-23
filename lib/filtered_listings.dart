import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheet.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/string_to_latlng.dart';

class FilteredListingsPage extends StatelessWidget {
  final String filterPrimaryType;
  final List<Map<String, dynamic>> listings;

  const FilteredListingsPage({
    required this.filterPrimaryType,
    required this.listings,
    super.key,
  });

  Future<List> sortListings() async {
    if (listings.isEmpty) {
      throw "No listings exist";
    } else if (currentLatLng != null) {
      // Sort listings by approximate distance
      final sortedListings = listings.map((listing) {
        LatLng destinationLatLng = stringToLatLng(listing['latLng']);
        final distance = asTheCrowFlies(currentLatLng, destinationLatLng);
        return {...listing, 'approximateDistanceMetres': distance};
      }).toList();

      sortedListings.sort((a, b) {
        int distanceA = a['approximateDistanceMetres'];
        int distanceB = b['approximateDistanceMetres'];
        return distanceA.compareTo(distanceB);
      });

      return sortedListings;
    }

    return listings;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sortListings(),
      initialData: listings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error sorting listings"));
        } else {
          final allListings = snapshot.data as List;

          // Filter the listings based on the primaryType
          final filteredListings = allListings.where((listing) => listing['primaryType'] == filterPrimaryType).toList();

          final homePageState = context.findAncestorStateOfType<HomePageState>();

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            separatorBuilder: (BuildContext context, int index) => Divider(color: Colors.grey[350]),
            itemCount: filteredListings.length,
            itemBuilder: (context, index) {
              final listing = filteredListings[index];
              final approximateDistanceMetres = listing['approximateDistanceMetres'] ?? 0;
              final approximateDistance = 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}';
              LatLng destinationLatLng = stringToLatLng(listing['latLng']);
              return ListingInfoSheet(
                title: listing['displayName'],
                categories: listing['secondaryType'] + ' • ' + listing['tertiaryType'],
                openingTimes: listing['startTime'] + ' - ' + listing['endTime'],
                approxDistance: approximateDistance,
                phoneNumber: listing['phone'],
                website: listing['website'],
                onGetDirections: () => {
                  if (homePageState != null)
                    {
                      homePageState.navigateToMapAndGetDirections(listing['id'], destinationLatLng, http.Client()),
                    }
                },
              );
            },
          );
        }
      },
    );
  }
}
