import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheet.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/string_to_latlng.dart';

class FilteredListingsPage extends StatefulWidget {
  final String filterPrimaryType;
  final List<Map<String, dynamic>> listings;

  const FilteredListingsPage({
    required this.filterPrimaryType,
    required this.listings,
    super.key,
  });

  @override
  State<FilteredListingsPage> createState() => _FilteredListingsPageState();
}

class _FilteredListingsPageState extends State<FilteredListingsPage> {
  // ignore: unused_field
  late Future<List> _sortedListings;
  bool isRefreshing = false;

  @override
  void initState() {
    _sortedListings = sortListings();
    super.initState();
  }

  Future<List> sortListings() async {
      if (listings.isEmpty) {
        throw Exception("No listings exist");
      }

    if (currentLatLng != null) {
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

  Future<void> refreshListings() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      listings = await fetchListings(http.Client());
    } finally {
      setState(() {
        _sortedListings = sortListings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sortedListings = sortListings(),
      initialData: listings,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
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
        } else {
          final allListings = snapshot.data as List;

          // Filter the listings based on the primaryType
          final filteredListings = allListings.where((listing) => listing['primaryType'] == widget.filterPrimaryType).toList();

          final homePageState = context.findAncestorStateOfType<HomePageState>();

          return RefreshIndicator(
            onRefresh: refreshListings,
            backgroundColor: Theme.of(context).colorScheme.primary,
            color: Theme.of(context).colorScheme.onPrimary,
            child: ListView.separated(
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
            ),
          );
        }
      },
    );
  }
}
