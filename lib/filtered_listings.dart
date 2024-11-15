import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/listings_info_sheet.dart';
import 'package:mill_road_winter_fair_app/main.dart';

class FilteredListingsPage extends StatelessWidget {
  final String filterPrimaryType;
  final http.Client client;

  const FilteredListingsPage({
    required this.filterPrimaryType,
    required this.client,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchFilteredListings(filterPrimaryType, client),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error fetching listings"));
        } else {
          final listings = snapshot.data as List;
          final homePageState =
          context.findAncestorStateOfType<HomePageState>();
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            separatorBuilder: (BuildContext context, int index) => Divider(color: Colors.grey[350]),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return ListingInfoSheet(
                title: listing['displayName'],
                categories:
                listing['secondaryType'] + ' • ' + listing['tertiaryType'],
                openingTimes: listing['startTime'] + ' - ' + listing['endTime'],
                phoneNumber: listing['phone'],
                website: listing['website'],
                onGetDirections: () => {
                  if (homePageState != null)
                    {
                      homePageState
                          .navigateToMapAndGetDirections(listing['id'], listing['plusCode'], http.Client()),
                    }
                },
              );
            },
          );
        }
      },
    );
  }

  Future<List> fetchFilteredListings(
      String primaryType, http.Client client) async {
    // Fetch all listings from the API
    final response = await client.get(Uri.parse('$mrwfApi/listings'));

    if (response.statusCode == 200) {
      // Decode the full list of listings
      final allListings = json.decode(response.body) as List;

      // Filter the listings based on the primaryType
      final filteredListings = allListings
          .where((listing) => listing['primaryType'] == primaryType)
          .toList();

      return filteredListings;
    } else {
      throw Exception("Failed to load listings");
    }
  }
}
