import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mill_road_winter_fair_app/globals.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';
import 'package:mill_road_winter_fair_app/map_page.dart';

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
  final Map<String, dynamic> theListing;
  // From the parent widget (calculated)
  final String approxDistance;
  final bool listingFavourited;
  final VoidCallback? onDetailsTapped;
  final VoidCallback? onFavouriteTapped;
  final Function onGetDirections;
  final void Function(VoidCallback) setStateFunction;
  final bool inDialog;

  const SpecificListingInfoSheet({
    required this.theListing,
    required this.approxDistance,
    required this.listingFavourited,
    this.onDetailsTapped,
    this.onFavouriteTapped,
    required this.onGetDirections,
    required this.setStateFunction,
    required this.inDialog,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    //debugPrint('SpecificListingInfoSheet build() called');
    String updatedTimes; // replaced with CANCELLED if appropriate
    Widget subDetails; // calculated subtitle/details field
    final id = theListing['id'] ?? '';
    final emoji = theListing['emoji'] ?? '';
    final title = theListing['title'] ?? '';
    final cancelled = theListing['cancelled'] == 'TRUE' ? true : false;
    final brickAndMortar = theListing['brickAndMortar'] == 'TRUE' ? true : false;
    final startTime = theListing['startTime'];
    final endTime = theListing['endTime'];
    final location = theListing['location'];
    final subtitle = theListing['subtitle'] ?? '';
    final latLng = stringToLatLng(theListing['latLng']);
    final phoneNumber = theListing['phone'] ?? '';
    final website = theListing['website'] ?? '';
    final email = theListing['email'] ?? '';
    final description = theListing['description'] ?? '';
    final imageURL = theListing['imageURL'] ?? '';

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
        TextSpan(text: "$subtitle\n$approxDistance", style: subSubStyle),
        TextSpan(text: updatedTimes, style: timeStyle),
        ]));
    } else {
      subDetails = Text.rich(textAlign: TextAlign.right, TextSpan(text: '$subtitle\n$approxDistance', style: timeStyle));
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (inDialog) ? null : () {
        HapticFeedback.lightImpact();
        showListingDetailsDialog(
          context, 
          //alertNoticePeriod,
          setStateFunction,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => MapPage(
            listings: listings, 
            onTabSelected: (_) => {}, 
            destinationId: id,
            destinationLatLng: latLng,
          ))),
          theListing, 
        );
      },
      child: Container(
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
                    if (brickAndMortar) TextSpan(style: subSubStyle, text: '🏢 '),
                    TextSpan(style: subSubStyle, text: location),
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
            if (inDialog) detailsColumn(context, description, website, email, phoneNumber, imageURL),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onFavouriteTapped,
                  padding: const EdgeInsets.all(0),
                  style: ElevatedButton.styleFrom(visualDensity: const VisualDensity(horizontal: -4, vertical: -2), 
                      padding: const EdgeInsets.all(0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  icon:FaIcon(
                    shadows: [Shadow( color: Theme.of(context).shadowColor, offset: const Offset(1, 3), blurRadius: 5)],
                    (listingFavourited) ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                    size: 22, color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (inDialog) Spacer(flex: 99) else const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(iconSize: 24, visualDensity: const VisualDensity(horizontal: 2, vertical: -2), 
                      padding: const EdgeInsets.all(0), elevation: 3, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onGetDirections();
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: Text('Directions'),
                ),
                Flexible(flex: 1, child: Container()),
                if (!inDialog && website.isNotEmpty) ...[const SizedBox(width: 6), Material(
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
                )],
                if (!inDialog && email.isNotEmpty) ...[const SizedBox(width: 6), Material(
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
                )],
                if (!inDialog && phoneNumber.isNotEmpty) ...[const SizedBox(width: 6), Material(
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
                )],
              ],
            ),
            // if we're on a modal bottom sheet, add lots of space to avoid bottom of screen; otherwise just a bit between listings
            if (onDetailsTapped == null && location != '') const SizedBox(height: 10),
            if (onDetailsTapped != null || location == '') const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Column detailsColumn(BuildContext context, String description, String website, String email, String phoneNumber, String imageURL) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0,
      children: [
        if (description.isNotEmpty || website.isNotEmpty || email.isNotEmpty || phoneNumber.isNotEmpty) const SizedBox(height: 8),
        if (description.isNotEmpty) ...[const SizedBox(height: 8), Flexible(child: Text(style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant), description))],
        if (imageURL.isNotEmpty) ...[const SizedBox(height: 8), Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: Image.network(
              imageURL,
              fit: BoxFit.scaleDown,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image);
              },
            ),
          ),
        )],
        if (website.isNotEmpty) ...[const SizedBox(height: 8), Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), text: 'Website: '),
                TextSpan(style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline), text: website, 
                    recognizer: TapGestureRecognizer()..onTap = () async {
                      HapticFeedback.lightImpact();
                      launchUrl(Uri.parse(website));
                    },
                ),
              ], 
            ),
          ), 
        )],
        if (email.isNotEmpty) ...[const SizedBox(height: 8), Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), text: 'Email: '),
                TextSpan(style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline), text: email,
                    recognizer: TapGestureRecognizer()..onTap = () async {
                      HapticFeedback.lightImpact();
                      final Uri mailUri = Uri(scheme: 'mailto', path: email);
                      if (await canLaunchUrl(mailUri)) {
                        await launchUrl(mailUri);
                      } else {
                        throw Exception('Could not launch email client');
                      }
                    },
                ),
              ], 
            ),
          ), 
        )],
        if (phoneNumber.isNotEmpty) ...[const SizedBox(height: 8), Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), text: 'Telephone: '),
                TextSpan(style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline), text: phoneNumber,
                  recognizer: TapGestureRecognizer()..onTap = () async {
                    HapticFeedback.lightImpact();
                    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      throw Exception('Could not launch $phoneNumber');
                    }
                  },
                ),
              ], 
            ),
          ), 
        )],
      ],
    );
  }
}

  Future<void> showListingDetailsDialog(
    BuildContext context,
    //int alertNoticePeriod,
    void Function(VoidCallback) setStateFunction,
//    final int? Function(PositionedEvent, int, int?) toggleAlertAction,
    Future<dynamic> Function() onGetDirections,
    Map<String, dynamic> listing,
  ) async {

    debugPrint('showListingDetailsDialog called');

    removeMiniPopup(); // just in case one was opened

    if (!context.mounted) return;
    final colorScheme = Theme.of(context).colorScheme;

    var distanceMessage = 'Distance unknown';

    listingDetailsDialogRoute = DialogRoute(context: context, barrierColor: Colors.black38, builder: (_) => StatefulBuilder(
      builder: (ctx2, setStateDialog) {
        if (currentLatLng != null) {
          int approximateDistanceMetres = asTheCrowFlies(
            currentLatLng!,
            stringToLatLng(listing['latLng']),
          );
          distanceMessage = '(${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)} away)';
        }
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 12), // margin from screen edges
          shape: RoundedRectangleBorder(side: BorderSide(color: colorScheme.onSecondary, width: 0.5), borderRadius: BorderRadius.circular(12)),
          backgroundColor: colorScheme.surfaceContainerLowest,
          shadowColor: colorScheme.surfaceContainerHighest,
          elevation: 12,
          child: Scrollbar(
            thumbVisibility: Platform.isIOS ? false : true,
            thickness: 4,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: SpecificListingInfoSheet(
                  theListing: listing,
                  approxDistance: distanceMessage,
                  listingFavourited: favouriteListingKeys.value.contains(listing['id']),
                  onFavouriteTapped: () {
                    favouriteOrNotListing(listing['id']);
                    setStateFunction.call;
                    setStateDialog(() {});
                  },
                  onGetDirections: () async {
                    safeRemoveRoute(context, listingDetailsDialogRoute); // i.e. pop this dialog
                    onGetDirections.call();
                  },
                  setStateFunction: setStateDialog,
                  inDialog: true,
                ),
              ),
            ),
          ),
        );
      }
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


  void favouriteOrNotListing(String id) {
    if (favouriteListingKeys.value.contains(id)) {
      favouriteListingKeys.value = {...favouriteListingKeys.value}..remove(id);
    } else {
      favouriteListingKeys.value = {...favouriteListingKeys.value, id};
    }
    _saveFavourites();
  }


  Future<void> _saveFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favouritesList', favouriteListingKeys.value.toList());
  }

