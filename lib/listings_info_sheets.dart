import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final bool detailsVisible;
  final bool listingFavourited;
  final VoidCallback? onDetailsTapped;
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
    required this.detailsVisible,
    required this.listingFavourited,
    this.onDetailsTapped,
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
    final titleStyle = basicTitleStyle.copyWith(decoration: cancelled ? TextDecoration.lineThrough : TextDecoration.none);
    updatedTimes = cancelled ? 'CANCELLED' : "$startTime—$endTime";

    final subStyle = titleStyle.copyWith(fontSize: 14);
    final subSubStyle = subStyle.copyWith(fontWeight: FontWeight.normal);

    // Determine if the event has ended, update text style accordingly
    final bool ended = hasEventEnded(endTime);
    final timeStyle = subSubStyle.copyWith(
      color: ended || cancelled ? Colors.red : Theme.of(context).colorScheme.onSurface,
      decoration: ended ? TextDecoration.lineThrough : TextDecoration.none,
    );

    if (location == '') { // this SpecificListingInfoSheet must be within a Group modal, so display differently
       subDetails = Text.rich(textAlign: TextAlign.right, TextSpan(children: [
        TextSpan(text: "$subtitle\n", style: subSubStyle),
        TextSpan(text: updatedTimes, style: timeStyle),
        ]));
    } else {
      subDetails = Text.rich(textAlign: TextAlign.right, TextSpan(text: subtitle, style: timeStyle));
    }

    return Container(
      padding: (inDialog) ? EdgeInsets.all(0) : EdgeInsets.fromLTRB(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Prepend the emoji if we have one
              if (emoji.isNotEmpty) Text('$emoji ', style: basicTitleStyle.copyWith(fontSize: 30)),
              Expanded(
                flex: 14,
                child: Text(title, style: titleStyle),
              ),
              const Expanded(flex: 1, child: SizedBox(width: 2)),
              Expanded(
                flex: 6,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: subDetails),
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
                  TextSpan(style: subSubStyle.copyWith(fontSize: 12), text: currentLatLng == null ? '' : ' $approxDistance'),
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
          if (detailsVisible && inDialog) detailsColumn(context),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: -4, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onGetDirections();
                },
                child: const Icon(Icons.directions_walk),
              ),
              // only display the Details button and spacer before it if there are details to display (and they're not always shown i.e. single bottom modal)
              if (onDetailsTapped != null && (description.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty)) const SizedBox(width: 6),
              // below is safeguard in case a listing has Email+Phone+Website on a small screen: do icon-only Details button
              if (onDetailsTapped != null && website.isNotEmpty && email.isNotEmpty && phoneNumber.isNotEmpty && MediaQuery.of(context).size.width <= 360)
                ElevatedButton(
                  style: detailsVisible ?
                    ElevatedButton.styleFrom(iconSize: 24, foregroundColor: Theme.of(context).colorScheme.onPrimary, backgroundColor: Theme.of(context).colorScheme.primary, visualDensity: const VisualDensity(horizontal: -4, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap)
                  :
                    ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: -4, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: onDetailsTapped,
                  child: const Icon(Icons.info),
              ) 
              else if (onDetailsTapped != null && (description.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty))
                ElevatedButton(
                  style: detailsVisible ?
                    ElevatedButton.styleFrom(iconSize: 24, foregroundColor: Theme.of(context).colorScheme.onPrimary, backgroundColor: Theme.of(context).colorScheme.primary, visualDensity: const VisualDensity(horizontal: -4, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap)
                  :
                    ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: -4, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: onDetailsTapped,
                  child: const Icon(Icons.info),
                ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: -4, vertical: -2), padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () => shareListing(title, location, startTime, endTime, context),
                child: (Platform.isAndroid) ? const Icon(Icons.share) : const Icon(Icons.ios_share),
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
          if (detailsVisible && !inDialog) detailsColumn(context),
          // if we're on a modal bottom sheet, add lots of space to avoid bottom of screen; otherwise just a bit between listings
          if (onDetailsTapped == null && location != '') const SizedBox(height: 20),
          if (onDetailsTapped != null || location == '') const SizedBox(height: 4),
        ],
      ),
    );
  }

  Column detailsColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0,
      children: [
        if (description.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty) const SizedBox(height: 8),
        if (description.isNotEmpty) const SizedBox(height: 8),
        if (description.isNotEmpty) Row(
          children: [
            Flexible(
              child: Text(style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant), description),
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
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    var distanceMessage = 'Distance unknown';
    if (currentLatLng != null) {
      int approximateDistanceMetres = asTheCrowFlies(
        currentLatLng!,
        event.latLng,
      );
      distanceMessage = '(approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)})';
    }

    listingDetailsDialogRoute = DialogRoute(context: context, barrierColor: Colors.black38, builder: (_) => StatefulBuilder(
      builder: (ctx2, setStateDialog) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 12), // margin from screen edges
          shape: RoundedRectangleBorder(side: BorderSide(color: colorScheme.onSecondary, width: 0.5), borderRadius: BorderRadius.circular(12)),
          backgroundColor: colorScheme.surfaceContainerLowest,
          shadowColor: colorScheme.surfaceContainerHighest,
          elevation: 12,
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SpecificListingInfoSheet(
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
                detailsVisible: true,
                listingFavourited: favouriteListingKeys.value.contains(event.id),
                onFavouriteTapped: () {
                  favouriteOrNotListing(event);
                  setStateFunction.call;
                  setStateDialog(() {});
                },
                onGetDirections: () async {
                  safeRemoveRoute(context, listingDetailsDialogRoute); // i.e. pop this dialog
                  onGetDirections.call();
                },
                inDialog: true,
              ),
            ),
          ),
        );
      },
    ));
    await Navigator.of(context).push(listingDetailsDialogRoute!);
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
      favouriteListingKeys.value = {...favouriteListingKeys.value}..remove(theEvent.id);
    } else {
      favouriteListingKeys.value = {...favouriteListingKeys.value, theEvent.id};
    }
    _saveFavourites();
  }


  Future<void> _saveFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favouritesList', favouriteListingKeys.value.toList());
  }

