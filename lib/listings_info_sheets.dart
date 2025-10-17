import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupListingInfoSheet extends StatelessWidget {
  final String title;
  final String categories;
  final String openingTimes;
  final String approxDistance;

  const GroupListingInfoSheet({
    required this.title,
    required this.categories,
    required this.openingTimes,
    required this.approxDistance,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('GroupListingInfoSheet build() called');
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        border: BoxBorder.all(width: 1, color: Colors.grey[700]!),
      ),
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 42), // cap text height
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  openingTimes,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimary),
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
                flex: 7,
                child: Text(
                  categories,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
              if (currentLatLng != null)
                Expanded(
                  flex: 3,
                  child: Text(
                    approxDistance,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimary),
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SpecificListingInfoSheet extends StatelessWidget {
  final String title;
  final String categories;
  final String openingTimes;
  final String approxDistance;
  final String phoneNumber;
  final String website;
  final Function onGetDirections;

  const SpecificListingInfoSheet({
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
    debugPrint('SpecificListingInfoSheet build() called');
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
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 7, child: Text(categories)),
              if (currentLatLng != null)
                Expanded(
                  flex: 3,
                  child: Text(
                    approxDistance,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (phoneNumber.isNotEmpty)
            GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
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
              Flexible(
                flex: 8,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onGetDirections();
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: const FittedBox(child: Text('Get Directions')),
                ),
              ),
              Flexible(flex: 1, child: Container()),
              if (website.isNotEmpty)
                Flexible(
                  flex: 8,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      launchUrl(Uri.parse(website));
                    },
                    icon: const Icon(Icons.public),
                    label: const FittedBox(child: Text('Open Website')),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SimplifiedListingInfoSheet extends StatelessWidget {
  final String title;
  final String categories;
  final String openingTimes;
  final String phoneNumber;
  final String website;
  final Function onGetDirections;

  const SimplifiedListingInfoSheet({
    required this.title,
    required this.categories,
    required this.openingTimes,
    required this.phoneNumber,
    required this.website,
    required this.onGetDirections,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('SimplifiedListingInfoSheet build() called');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 6,
                child: Text(categories),
              ),
              if (phoneNumber.isNotEmpty)
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      } else {
                        throw Exception('Could not launch $phoneNumber');
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.phone, color: Colors.blue),
                        const SizedBox(width: 2),
                        Text(phoneNumber),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 8,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onGetDirections();
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: const FittedBox(child: Text('Get Directions')),
                ),
              ),
              Flexible(flex: 1, child: Container()),
              if (website.isNotEmpty)
                Flexible(
                  flex: 8,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      launchUrl(Uri.parse(website));
                    },
                    icon: const Icon(Icons.public),
                    label: const FittedBox(child: Text('Open Website')),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
