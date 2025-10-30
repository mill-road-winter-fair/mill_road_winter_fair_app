import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:url_launcher/url_launcher.dart';

// Function to determine if the event has ended based on endTime string
bool hasEventEnded(String endTime) {
  // Hardcoded fair date for 2025, change this today's date for testing
  final fairDate = DateTime(2025, 12, 6);

  try {
    final parts = endTime.split(':');
    final endHour = int.parse(parts[0]);
    final endMinute = parts.length > 1 ? int.parse(parts[1]) : 0;

    final endDateTime = DateTime(
      fairDate.year,
      fairDate.month,
      fairDate.day,
      endHour,
      endMinute,
    );

    return DateTime.now().isAfter(endDateTime);
  } catch (_) {
    return false; // default to not ended if parsing fails
  }
}

class GroupListingInfoSheet extends StatelessWidget {
  final String title;
  final String categories;
  final String startTime;
  final String endTime;
  final String approxDistance;

  const GroupListingInfoSheet({
    required this.title,
    required this.categories,
    required this.startTime,
    required this.endTime,
    required this.approxDistance,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('GroupListingInfoSheet build() called');

    // Determine if the event has ended, update text style accordingly
    final bool ended = hasEventEnded(endTime);
    final timeStyle = TextStyle(
      fontSize: 14,
      color: Theme.of(context).colorScheme.onPrimary,
      decoration: ended ? TextDecoration.lineThrough : TextDecoration.none,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        border: BoxBorder.all(width: 1, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 13,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 42), // cap text height
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ),
              ),
              const Expanded(flex: 1, child: SizedBox(width: 2)),
              Expanded(
                flex: 7,
                child: Text(
                  "$startTime—$endTime",
                  style: timeStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
//          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 10,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      categories,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
              ),
              const Expanded(flex: 1, child: SizedBox(width: 2)),
              if (currentLatLng != null)
                Expanded(
                  flex: 10,
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
  final String secondaryType;
  final String tertiaryType;
  final String startTime;
  final String endTime;
  final String approxDistance;
  final String phoneNumber;
  final String website;
  final String email;
  final String description;
  final bool detailsVisible;
  final VoidCallback? onToggle;
  final Function onGetDirections;

  const SpecificListingInfoSheet({
    required this.title,
    required this.secondaryType,
    required this.tertiaryType,
    required this.startTime,
    required this.endTime,
    required this.approxDistance,
    required this.phoneNumber,
    required this.website,
    required this.email,
    required this.description,
    required this.detailsVisible,
    this.onToggle,
    required this.onGetDirections,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('SpecificListingInfoSheet build() called');

    // Determine if the event has ended, update text style accordingly
    final bool ended = hasEventEnded(endTime);
    final timeStyle = TextStyle(
      fontSize: 14,
      color: ended ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
      decoration: ended ? TextDecoration.lineThrough : TextDecoration.none,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        4.0 + ((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt(),
        12,
        4.0 + ((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt(),
        12
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 0,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 14,
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Expanded(flex: 1, child: SizedBox(width: 2)),
              Expanded(
                flex: 6,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(
                  tertiaryType,
                  style: timeStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              ),
            ],
          ),
          if (secondaryType != '') const SizedBox(height: 8),
          if (secondaryType != '') Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 14, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: secondaryType),
                  TextSpan(style: const TextStyle(fontSize: 12), text: currentLatLng == null ? '' : ' ($approxDistance)'),
                ], ), 
              ), ),
              ),
              const Expanded(flex: 1, child: SizedBox(width: 2)),
              Expanded(
                flex: 6,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(
                  "$startTime—$endTime",
                  style: timeStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              ),
            ],
          ),
          if (secondaryType != '') const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: 2, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onGetDirections();
                },
                icon: const Icon(Icons.directions_walk),
                label: const FittedBox(child: Text('Directions')),
              ),
              // only display the Details button, and the spacer before it, if there are some details to display (and they're not always shown)
              if (onToggle != null && (description.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty)) const SizedBox(width: 8),
              // below is safeguard in case a listing has Email+Phone+Website on a small screen: do icon-only Details button
              if (onToggle != null && website.isNotEmpty && email.isNotEmpty && phoneNumber.isNotEmpty && MediaQuery.of(context).size.width < 350)
                ElevatedButton(
                  style: detailsVisible ?
                    ElevatedButton.styleFrom(iconSize: 24, foregroundColor: Theme.of(context).colorScheme.onPrimary, backgroundColor: Theme.of(context).colorScheme.primary, visualDensity: const VisualDensity(horizontal: -1, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap)
                  :
                    ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: -1, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: onToggle,
                  child: const Icon(Icons.info),
              ) 
              else if (onToggle != null && (description.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty))
                ElevatedButton.icon(
                  style: detailsVisible ?
                    ElevatedButton.styleFrom(iconSize: 24, foregroundColor: Theme.of(context).colorScheme.onPrimary, backgroundColor: Theme.of(context).colorScheme.primary, visualDensity: const VisualDensity(horizontal: 2, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap)
                  :
                    ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: 2, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: onToggle,
                  icon: const Icon(Icons.info),
                  label: const FittedBox(child: Text('Details')),
                ),
              Flexible(flex: 1, child: Container()),
              if (website.isNotEmpty) const SizedBox(width: 6),
              if (website.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    launchUrl(Uri.parse(website));
                  },
                  child: Row(
                    children: [
                      Icon(Icons.public, color: Theme.of(context).colorScheme.primary, size: 30, shadows: [Shadow(offset: const Offset(1, 3), blurRadius: 5, color: Theme.of(context).shadowColor)]),
                    ],
                  ),
                ),
                if (email.isNotEmpty) const SizedBox(width: 6),
                if (email.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final Uri mailUri = Uri(scheme: 'mailto', path: email);
                      if (await canLaunchUrl(mailUri)) {
                        await launchUrl(mailUri);
                      } else {
                        throw Exception('Could not launch email client');
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.email, color: Theme.of(context).colorScheme.primary, size: 30, shadows: [Shadow(offset: const Offset(1, 3), blurRadius: 5, color: Theme.of(context).shadowColor)]),
                      ],
                    ),
                  ),
                if (phoneNumber.isNotEmpty) const SizedBox(width: 8),
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
                        Icon(Icons.phone, color: Theme.of(context).colorScheme.primary, size: 30, shadows: [Shadow(offset: const Offset(1, 3), blurRadius: 5, color: Theme.of(context).shadowColor)]),
                      ],
                    ),
                  ),
            ],
          ),
          if (detailsVisible)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 0,
              children: [
                if (description.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty) const SizedBox(height: 8),
                if (description.isNotEmpty) const SizedBox(height: 8),
                if (description.isNotEmpty) Row(
                  children: [
                    Flexible(
                      child: Text(style: const TextStyle(fontSize: 12), description),
                    ),
                  ],
                ),
                if (website.isNotEmpty) const SizedBox(height: 8),
                if (website.isNotEmpty) Row(
                  children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), text: 'Website: '),
                              TextSpan(style: const TextStyle(fontSize: 12), text: website),
                            ], 
                          ),
                        ), 
                      ),
                  ],
                ),
                if (email.isNotEmpty) const SizedBox(height: 8),
                if (email.isNotEmpty) Row(
                  children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), text: 'Email: '),
                              TextSpan(style: const TextStyle(fontSize: 12), text: email),
                            ], 
                          ),
                        ), 
                      ),
                  ],
                ),
                if (phoneNumber.isNotEmpty) const SizedBox(height: 8),
                if (phoneNumber.isNotEmpty) Row(
                  children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), text: 'Telephone: '),
                              TextSpan(style: const TextStyle(fontSize: 12), text: phoneNumber),
                            ], 
                          ),
                        ), 
                      ),
                  ],
                ),
              ],
            ),
          // if we're on a modal bottom sheet, add some space
          if (onToggle == null && secondaryType != '') const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class SimplifiedListingInfoSheet extends StatelessWidget {
  final String title;
  final String categories;
  final String startTime;
  final String endTime;
  final String phoneNumber;
  final String website;
  final Function onGetDirections;

  const SimplifiedListingInfoSheet({
    required this.title,
    required this.categories,
    required this.startTime,
    required this.endTime,
    required this.phoneNumber,
    required this.website,
    required this.onGetDirections,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('SimplifiedListingInfoSheet build() called');

    // Determine if the event has ended, update text style accordingly
    final bool ended = hasEventEnded(endTime);
    final timeStyle = TextStyle(
      fontSize: 14,
      color: ended ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
      decoration: ended ? TextDecoration.lineThrough : TextDecoration.none,
    );

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
                  "$startTime - $endTime",
                  style: timeStyle,
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
