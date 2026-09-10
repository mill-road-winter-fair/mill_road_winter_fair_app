import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'helpers.dart';
import 'listings_info_sheets.dart';

/// The complete listing, shared by the list, map and timetable entry points.
class ListingDetailsPage extends StatefulWidget {
  final SpecificListingInfoSheet listing;

  const ListingDetailsPage({required this.listing, super.key});

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  final _aboutKey = GlobalKey();
  late bool _favourited = widget.listing.listingFavourited;

  Future<void> _launch(Uri uri) async {
    HapticFeedback.lightImpact();
    try {
      if (await launchUrl(uri)) return;
    } catch (_) {
      // Keep the listing usable if no app can handle this contact method.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to open this link. Please try again.')),
      );
    }
  }

  Widget _contact(IconData icon, String label, String value, Uri uri) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _launch(uri),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final location = listing.location;
    final imageUrl = listing.imageURL.trim();
    final ended = hasEventEnded(listing.endTime);
    final website = listing.website.trim();
    final email = listing.email.trim();
    final phone = listing.phoneNumber.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Listing details')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, synchronous) =>
                              AspectRatio(aspectRatio: 16 / 9, child: child),
                          semanticLabel: listing.title,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ColoredBox(
                                color: colors.surfaceContainerHighest,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                            );
                          },
                          errorBuilder: (_, error, stack) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (listing.emoji.isNotEmpty) ...[
                      Text(listing.emoji, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      listing.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: listing.cancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (listing.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(listing.subtitle,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: colors.primary)),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fact(
                              Icons.schedule,
                              listing.cancelled
                                  ? 'CANCELLED'
                                  : '${listing.startTime}–${listing.endTime}${ended ? ' · Ended' : ''}'),
                          if (location.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _fact(Icons.place_outlined, location),
                          ],
                          if (listing.approxDistance.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _fact(
                                Icons.directions_walk, listing.approxDistance),
                          ],
                          if (listing.brickAndMortar) ...[
                            const SizedBox(height: 12),
                            _fact(Icons.storefront_outlined, 'Local business'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: listing.onFavouriteTapped == null
                              ? null
                              : () {
                                  listing.onFavouriteTapped!();
                                  setState(() => _favourited = !_favourited);
                                },
                          icon: Icon(_favourited
                              ? Icons.favorite
                              : Icons.favorite_border),
                          label: Text(_favourited ? 'Favourited' : 'Favourite'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            listing.onGetDirections();
                          },
                          icon: const Icon(Icons.directions_walk),
                          label: const Text('Directions'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Scrollable.ensureVisible(
                            _aboutKey.currentContext!,
                            duration: const Duration(milliseconds: 300),
                          ),
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Info'),
                        ),
                        Builder(
                            builder: (shareContext) => OutlinedButton.icon(
                                  onPressed: () => shareListing(
                                      listing.title,
                                      location,
                                      listing.startTime,
                                      listing.endTime,
                                      shareContext),
                                  icon: Icon(Platform.isAndroid
                                      ? Icons.share
                                      : Icons.ios_share),
                                  label: const Text('Share'),
                                )),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text('About',
                        key: _aboutKey,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      listing.description.trim().isEmpty
                          ? 'Explore this listing at the fair.'
                          : listing.description,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                    if (website.isNotEmpty ||
                        email.isNotEmpty ||
                        phone.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text('Get in touch',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(children: [
                          if (website.isNotEmpty)
                            _contact(
                                Icons.public,
                                'Website',
                                website,
                                Uri.parse(website.contains('://')
                                    ? website
                                    : 'https://$website')),
                          if (email.isNotEmpty)
                            _contact(Icons.email_outlined, 'Email', email,
                                Uri(scheme: 'mailto', path: email)),
                          if (phone.isNotEmpty)
                            _contact(Icons.phone_outlined, 'Telephone', phone,
                                Uri(scheme: 'tel', path: phone)),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fact(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      );
}
