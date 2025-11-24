import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:url_launcher/url_launcher.dart';

// Hardcoded fair date for 2025; change this today's date for testing
final fairDate = DateTime(2025, 12, 6);

// Function to determine if the event has ended based on endTime string
bool hasEventEnded(String endTime) {
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

// Function to determine if the event is today
bool isItEventDay() {
  return DateUtils.isSameDay(fairDate, DateTime.now());
}

// Identifier and function for determining if the event has been marked as cancelled
const cancelIdentifier = 'CANCELLED'; // must be at the very start of the description; anything else can follow
bool hasEventBeenCancelled(String description) {
  return (description.length >= cancelIdentifier.length && description.substring(0, cancelIdentifier.length) == cancelIdentifier);
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
  final String location;
  final String subtitle;
  final String startTime;
  final String endTime;
  final String approxDistance;
  final String phoneNumber;
  final String website;
  final String email;
  final String description;
  final bool detailsVisible;
  final bool listingFavourited;
  final VoidCallback? onDetailsTapped;
  final VoidCallback? onFavouriteTapped;
  final Function onGetDirections;

  const SpecificListingInfoSheet({
    required this.title,
    required this.location,
    required this.subtitle,
    required this.startTime,
    required this.endTime,
    required this.approxDistance,
    required this.phoneNumber,
    required this.website,
    required this.email,
    required this.description,
    required this.detailsVisible,
    required this.listingFavourited,
    this.onDetailsTapped,
    this.onFavouriteTapped,
    required this.onGetDirections,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('SpecificListingInfoSheet build() called');
    String updatedDescription; // with cancel identifier removed if appropriate
    String updatedTimes; // replaced with CANCELLED if appropriate

    // Determine if the event has been cancelled, update text style accordingly
    final bool cancelled = hasEventBeenCancelled(description);
    final titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
      decoration: cancelled ? TextDecoration.lineThrough : TextDecoration.none,
    );
    updatedDescription = cancelled ? description.substring(cancelIdentifier.length) : description;
    updatedTimes = cancelled ? cancelIdentifier : "$startTime—$endTime";

    final subStyle = titleStyle.copyWith(fontSize: 14);
    final subSubStyle = subStyle.copyWith(fontWeight: FontWeight.normal);

    // Determine if the event has ended, update text style accordingly
    final bool ended = hasEventEnded(endTime);
    final timeStyle = subSubStyle.copyWith(
      color: ended || cancelled ? Colors.red : Theme.of(context).colorScheme.onSurface,
      decoration: ended ? TextDecoration.lineThrough : TextDecoration.none,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        4.0 + ((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt(),
        8,
        4.0 + ((MediaQuery.of(context).size.height.toInt() - 500) / 30).toInt(),
        12
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 0,
        children: [
          // if we're on a modal bottom sheet, add a bit of space to avoid radius at top of dialog
          if (onDetailsTapped == null && location != '') const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 14,
                child: Text(
                  title,
                  style: titleStyle,
                ),
              ),
              const Expanded(flex: 1, child: SizedBox(width: 2)),
              Expanded(
                flex: 6,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(
                  subtitle,
                  style: subStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              ),
            ],
          ),
          // add location (and space before) unless it's blank (which means it's a bottom modal group list)
          if (location != '') const SizedBox(height: 8),
          if (location != '') Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 14, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text.rich(
                TextSpan(children: [
                  TextSpan(style: subSubStyle, text: location),
                  TextSpan(style: subSubStyle.copyWith(fontSize: 12), text: currentLatLng == null ? '' : ' ($approxDistance)'),
                ], ), 
              ), ),
              ),
              const Expanded(flex: 1, child: SizedBox(width: 2)),
              Expanded(
                flex: 6,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(
                  updatedTimes,
                  style: timeStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onFavouriteTapped,
                padding: const EdgeInsets.all(0),
                style: ElevatedButton.styleFrom(visualDensity: const VisualDensity(horizontal: -4, vertical: -2), padding: const EdgeInsets.all(0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                icon:FaIcon(
                  shadows: [Shadow( color: Theme.of(context).shadowColor, offset: const Offset(1, 3), blurRadius: 5)],
                  (listingFavourited) ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                  size: 22, color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: 2, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onGetDirections();
                },
                icon: const Icon(Icons.directions_walk),
                label: const FittedBox(child: Text('Directions')),
              ),
              // only display the Details button and spacer before it if there are details to display (and they're not always shown i.e. single bottom modal)
              if (onDetailsTapped != null && (updatedDescription.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty)) const SizedBox(width: 8),
              // below is safeguard in case a listing has Email+Phone+Website on a small screen: do icon-only Details button
              if (onDetailsTapped != null && website.isNotEmpty && email.isNotEmpty && phoneNumber.isNotEmpty && MediaQuery.of(context).size.width < 360)
                ElevatedButton(
                  style: detailsVisible ?
                    ElevatedButton.styleFrom(iconSize: 24, foregroundColor: Theme.of(context).colorScheme.onPrimary, backgroundColor: Theme.of(context).colorScheme.primary, visualDensity: const VisualDensity(horizontal: -4, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap)
                  :
                    ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: -4, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: onDetailsTapped,
                  child: const Icon(Icons.info),
              ) 
              else if (onDetailsTapped != null && (updatedDescription.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty))
                ElevatedButton.icon(
                  style: detailsVisible ?
                    ElevatedButton.styleFrom(iconSize: 24, foregroundColor: Theme.of(context).colorScheme.onPrimary, backgroundColor: Theme.of(context).colorScheme.primary, visualDensity: const VisualDensity(horizontal: 2, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap)
                  :
                    ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: 2, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: onDetailsTapped,
                  icon: const Icon(Icons.info),
                  label: const FittedBox(child: Text('Details')),
                ),
              Flexible(flex: 1, child: Container()),
              if (website.isNotEmpty) const SizedBox(width: 6),
              if (website.isNotEmpty)
                Material(
                  shape: const CircleBorder(),
                  elevation: 3,
                  color: Theme.of(context).colorScheme.primary,
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      launchUrl(Uri.parse(website));
                    },
                    customBorder: const CircleBorder(),
                    radius: 8,
                    child:  Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.public,
                        size: 22,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              if (email.isNotEmpty) const SizedBox(width: 6),
              if (email.isNotEmpty)
                Material(
                  shape: const CircleBorder(),
                  elevation: 3,
                  color: Theme.of(context).colorScheme.primary,
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final Uri mailUri = Uri(scheme: 'mailto', path: email);
                      if (await canLaunchUrl(mailUri)) {
                        await launchUrl(mailUri);
                      } else {
                        throw Exception('Could not launch email client');
                      }
                    },
                    customBorder: const CircleBorder(),
                    radius: 8,
                    child:  Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.email,
                        size: 22,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              if (phoneNumber.isNotEmpty) const SizedBox(width: 6),           
              if (phoneNumber.isNotEmpty)
                Material(
                  shape: const CircleBorder(),
                  elevation: 3,
                  color: Theme.of(context).colorScheme.primary,
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      } else {
                        throw Exception('Could not launch $phoneNumber');
                      }
                    },
                    customBorder: const CircleBorder(),
                    radius: 8,
                    child:  Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.phone,
                        size: 22,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
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
                if (updatedDescription.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty) const SizedBox(height: 8),
                if (updatedDescription.isNotEmpty) const SizedBox(height: 8),
                if (updatedDescription.isNotEmpty) Row(
                  children: [
                    Flexible(
                      child: Text(style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant), updatedDescription),
                    ),
                  ],
                ),
                if (website.isNotEmpty) const SizedBox(height: 8),
                if (website.isNotEmpty) GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    launchUrl(Uri.parse(website));
                  },
                  child: Row(
                    children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), text: 'Website: '),
                                TextSpan(style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline), text: website),
                              ], 
                            ),
                          ), 
                        ),
                    ],
                  ),
                ),
                if (email.isNotEmpty) const SizedBox(height: 8),
                if (email.isNotEmpty) GestureDetector(
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
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), text: 'Email: '),
                                TextSpan(style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline), text: email),
                              ], 
                            ),
                          ), 
                        ),
                    ],
                  ),
                ),
                if (phoneNumber.isNotEmpty) const SizedBox(height: 8),
                if (phoneNumber.isNotEmpty) GestureDetector(
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
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), text: 'Telephone: '),
                                TextSpan(style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline), text: phoneNumber),
                              ], 
                            ),
                          ), 
                        ),
                    ],
                  ),
                ),
              ],
            ),
          // if we're on a modal bottom sheet, add lots of space to avoid bottom of screen; otherwise just a bit between listings
          if (onDetailsTapped == null && location != '') const SizedBox(height: 20),
          if (onDetailsTapped != null || location == '') const SizedBox(height: 4),
        ],
      ),
    );
  }
}