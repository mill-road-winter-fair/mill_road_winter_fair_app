import 'package:flutter/material.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingInfoSheet extends StatelessWidget {
  final String title;
  final String categories;
  final String openingTimes;
  final String approxDistance;
  final String phoneNumber;
  final String website;
  final Function onGetDirections;

  const ListingInfoSheet({
    required this.title,
    required this.categories,
    required this.openingTimes,
    required this.approxDistance,
    required this.phoneNumber,
    required this.website,
    required this.onGetDirections,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 7,
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  openingTimes,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  flex: 5,
                  child: Text(categories)
              ),
              if (approxDistance != "")
                Expanded(
                  flex: 5,
                  child: Text(
                    approxDistance,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (phoneNumber.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  throw Exception('Could not launch $phoneNumber');
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(phoneNumber),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (globalIndex == 0) {
                    Navigator.pop(context);
                  }
                  onGetDirections();
                },
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
              ),
              if (website.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    launchUrl(Uri.parse(website));
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('Open website'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
