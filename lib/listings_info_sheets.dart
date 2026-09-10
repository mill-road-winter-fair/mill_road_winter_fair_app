import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mill_road_winter_fair_app/listing_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

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
        border: BoxBorder.all(
            width: 1, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  constraints:
                      const BoxConstraints(maxHeight: 42), // cap text height
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary),
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
          // const SizedBox(height: 8),
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
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              ),
              const Expanded(flex: 1, child: SizedBox(width: 2)),
              if (currentLatLng != null)
                Expanded(
                  flex: 10,
                  child: Text(
                    approxDistance,
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimary),
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
  // From the db
  final bool cancelled;
  final bool brickAndMortar;
  final String emoji;
  final String title;
  final String subtitle;
  final String location;
  final String description;
  final String email;
  final String website;
  final String phoneNumber;
  final String imageURL;
  final String startTime;
  final String endTime;
  // From the parent widget (calculated)
  final String approxDistance;
  final bool listingFavourited;

  final VoidCallback? onFavouriteTapped;
  final Function onGetDirections;
  final bool inDialog;

  const SpecificListingInfoSheet({
    required this.cancelled,
    required this.brickAndMortar,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.description,
    required this.email,
    required this.website,
    required this.phoneNumber,
    required this.imageURL,
    required this.startTime,
    required this.endTime,
    required this.approxDistance,
    required this.listingFavourited,
    this.onFavouriteTapped,
    required this.onGetDirections,
    required this.inDialog,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    //debugPrint('SpecificListingInfoSheet build() called');
    String updatedTimes; // replaced with CANCELLED if appropriate
    Widget subDetails; // calculated subtitle/details field

    // Determine if the event has been cancelled, update text style accordingly
    final basicTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final titleStyle = basicTitleStyle.copyWith(
        decoration:
            cancelled ? TextDecoration.lineThrough : TextDecoration.none);
    updatedTimes = cancelled ? 'CANCELLED' : "$startTime—$endTime";

    final subStyle = titleStyle.copyWith(fontSize: 14);
    final subSubStyle = subStyle.copyWith(fontWeight: FontWeight.normal);

    // Determine if the event has ended, update text style accordingly
    final bool ended = hasEventEnded(endTime);
    final timeStyle = subSubStyle.copyWith(
      color: ended || cancelled
          ? Colors.red
          : Theme.of(context).colorScheme.onSurface,
      decoration: ended ? TextDecoration.lineThrough : TextDecoration.none,
    );

    if (location == '') {
      // this SpecificListingInfoSheet must be within a Group modal, so display differently
      subDetails = Text.rich(
          textAlign: TextAlign.right,
          TextSpan(children: [
            TextSpan(text: "$subtitle\n", style: subSubStyle),
            TextSpan(text: updatedTimes, style: timeStyle),
          ]));
    } else {
      subDetails = Text.rich(
          textAlign: TextAlign.right,
          TextSpan(text: subtitle, style: timeStyle));
    }

    return Container(
      padding: (inDialog)
          ? EdgeInsets.all(0)
          : EdgeInsets.fromLTRB(
              4.0 +
                  ((MediaQuery.of(context).size.height.toInt() - 500) / 30)
                      .toInt(),
              8,
              4.0 +
                  ((MediaQuery.of(context).size.height.toInt() - 500) / 30)
                      .toInt(),
              12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 0,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Prepend the emoji if we have one
              if (emoji.isNotEmpty)
                Text('$emoji ', style: basicTitleStyle.copyWith(fontSize: 30)),
              Expanded(
                flex: 14,
                child: Text(title, style: titleStyle),
              ),
              const Expanded(flex: 1, child: SizedBox(width: 2)),
              Expanded(
                flex: 6,
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: subDetails),
              ),
            ],
          ),
          // add location (and space before) unless it's blank (which means it's a bottom modal group list)
          if (location != '') const SizedBox(height: 8),
          if (location != '')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 14,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(style: subSubStyle, text: location),
                          TextSpan(
                              style: subSubStyle.copyWith(fontSize: 12),
                              text: currentLatLng == null
                                  ? ''
                                  : ' $approxDistance'),
                        ],
                      ),
                    ),
                  ),
                ),
                const Expanded(flex: 1, child: SizedBox(width: 2)),
                Expanded(
                  flex: 6,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
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
                tooltip: listingFavourited ? 'Remove favourite' : 'Favourite',
                onPressed: onFavouriteTapped,
                padding: const EdgeInsets.all(0),
                style: ElevatedButton.styleFrom(
                    visualDensity:
                        const VisualDensity(horizontal: -4, vertical: -2),
                    padding: const EdgeInsets.all(0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                icon: FaIcon(
                  shadows: [
                    Shadow(
                        color: Theme.of(context).shadowColor,
                        offset: const Offset(1, 3),
                        blurRadius: 5)
                  ],
                  (listingFavourited)
                      ? FontAwesomeIcons.solidHeart
                      : FontAwesomeIcons.heart,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    iconSize: 24,
                    visualDensity:
                        const VisualDensity(horizontal: -4, vertical: -2),
                    padding: const EdgeInsets.all(0),
                    elevation: 3,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onGetDirections();
                },
                child: const Icon(Icons.directions_walk),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    iconSize: 24,
                    visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -2),
                    padding: const EdgeInsets.all(0),
                    elevation: 3,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  openDetails(context);
                },
                child: const Icon(Icons.info),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    iconSize: 24,
                    visualDensity:
                        const VisualDensity(horizontal: -4, vertical: -2),
                    padding: const EdgeInsets.all(0),
                    elevation: 3,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () =>
                    shareListing(title, location, startTime, endTime, context),
                child: (Platform.isAndroid)
                    ? const Icon(Icons.share)
                    : const Icon(Icons.ios_share),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> openDetails(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ListingDetailsPage(listing: this),
    ));
  }
}

Future<void> showListingDetailsDialog(
  BuildContext context,
  PositionedEvent event,
  //int alertNoticePeriod,
  void Function(VoidCallback) setStateFunction,
//    final int? Function(PositionedEvent, int, int?) toggleAlertAction,
  Future<dynamic> Function() onGetDirections,
) async {
  debugPrint('showListingDetailsDialog called');

  removeMiniPopup(); // just in case one was opened

  if (!context.mounted) return;

  var distanceMessage = 'Distance unknown';
  if (currentLatLng != null) {
    int approximateDistanceMetres = asTheCrowFlies(
      currentLatLng!,
      event.latLng,
    );
    distanceMessage =
        '(approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)})';
  }

  final route = MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => ListingDetailsPage(
      listing: SpecificListingInfoSheet(
        cancelled: event.cancelled,
        brickAndMortar: event.brickAndMortar,
        emoji: event.emoji,
        title: event.name,
        subtitle: event.subtitle,
        location: event.location,
        description: event.description,
        email: event.email,
        website: event.website,
        phoneNumber: event.phoneNumber,
        imageURL: event.imageURL,
        startTime: formatTime(event.startTime),
        endTime: formatTime(event.endTime),
        approxDistance: distanceMessage,
        listingFavourited: favouriteListingKeys.value.contains(event.id),
        onFavouriteTapped: () {
          favouriteOrNotListing(event);
          setStateFunction(() {});
        },
        onGetDirections: () async {
          onGetDirections.call();
        },
        inDialog: true,
      ),
    ),
  );
  listingDetailsDialogRoute = route;
  await Navigator.of(context).push(route);
  if (identical(listingDetailsDialogRoute, route)) {
    listingDetailsDialogRoute = null;
  }
  removeMiniPopup(); // just in case one was opened
}

// Safe route removal with null/active checks
void safeRemoveRoute(BuildContext context, Route? route) {
  if (route != null && route.isActive && route.navigator != null) {
    try {
      Navigator.of(context).removeRoute(route);
    } catch (e) {
      debugPrint('safeRemoveRoute: error removing route: $e');
    }
  }
}

void favouriteOrNotListing(PositionedEvent theEvent) {
  if (favouriteListingKeys.value.contains(theEvent.id)) {
    favouriteListingKeys.value = {...favouriteListingKeys.value}
      ..remove(theEvent.id);
  } else {
    favouriteListingKeys.value = {...favouriteListingKeys.value, theEvent.id};
  }
  _saveFavourites();
}

Future<void> _saveFavourites() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
      'favouritesList', favouriteListingKeys.value.toList());
}
