import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/listing_details_page.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/themes.dart';

SpecificListingInfoSheet listing(
        {String imageURL = '',
        String description = 'Fresh doughnuts made locally.',
        bool cancelled = false,
        bool favourited = false,
        VoidCallback? favourite,
        VoidCallback? directions}) =>
    SpecificListingInfoSheet(
      cancelled: cancelled,
      brickAndMortar: true,
      emoji: '🍩',
      title: 'Glazed and Confused',
      subtitle: 'Food • Doughnuts',
      location: 'Gwydir St Car Park',
      description: description,
      email: 'hello@example.com',
      website: 'https://example.com',
      phoneNumber: '01223 111111',
      imageURL: imageURL,
      startTime: '10:30',
      endTime: '16:30',
      approxDistance: '100 m away',
      listingFavourited: favourited,
      onFavouriteTapped: favourite ?? () {},
      onGetDirections: directions ?? () {},
      inDialog: false,
    );

void main() {
  testWidgets('sheet only shows summary and four actions; Info opens full page',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: listing())));
    expect(find.text('Fresh doughnuts made locally.'), findsNothing);
    expect(find.byIcon(Icons.public), findsNothing);
    expect(find.byIcon(Icons.email), findsNothing);
    expect(find.byIcon(Icons.phone), findsNothing);
    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(3));
    await tester.tap(find.byIcon(Icons.info));
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailsPage), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Glazed and Confused'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Website'), 250);
    expect(find.text('Fresh doughnuts made locally.'), findsOneWidget);
    expect(find.text('hello@example.com'), findsOneWidget);
    expect(find.text('01223 111111'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailsPage), findsNothing);
    expect(find.text('Fresh doughnuts made locally.'), findsNothing);
  });

  testWidgets('full page favourite updates and directions returns to source',
      (tester) async {
    var favourites = 0;
    var directions = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: listing(
      favourite: () => favourites++,
      directions: () => directions++,
    ))));
    await tester.tap(find.byIcon(Icons.info));
    await tester.pumpAndSettle();
    expect(find.text('Info'), findsNothing);
    expect(find.byIcon(Icons.info_outline), findsNothing);
    final favouriteButton = find.widgetWithText(OutlinedButton, 'Favourite');
    expect(favouriteButton, findsOneWidget);
    expect(tester.widget<OutlinedButton>(favouriteButton).style, isNull);
    await tester.tap(favouriteButton);
    await tester.pump();
    expect(favourites, 1);
    final selectedButton = find.widgetWithText(OutlinedButton, 'Favourited');
    expect(selectedButton, findsOneWidget);
    final colors = Theme.of(tester.element(selectedButton)).colorScheme;
    expect(
        tester
            .widget<OutlinedButton>(selectedButton)
            .style!
            .backgroundColor!
            .resolve({}),
        colors.primary);
    await tester.tap(selectedButton);
    await tester.pump();
    expect(favourites, 2);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Favourite'))
            .style,
        isNull);
    await tester.tap(find.text('Directions'));
    await tester.pumpAndSettle();
    expect(directions, 1);
    expect(find.byType(ListingDetailsPage), findsNothing);
  });

  testWidgets('saved favourite starts highlighted', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ListingDetailsPage(listing: listing(favourited: true)),
    ));
    final button = find.widgetWithText(OutlinedButton, 'Favourited');
    expect(button, findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(button)
            .style!
            .backgroundColor!
            .resolve({}),
        Theme.of(tester.element(button)).colorScheme.primary);
  });

  testWidgets('title and subtitle sit beside the original sized emoji',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ListingDetailsPage(listing: listing()),
    ));
    final emoji = find.text('🍩');
    final title = find.text('Glazed and Confused');
    final subtitle = find.text('Food • Doughnuts');
    expect(tester.widget<Text>(emoji).style!.fontSize, 40);
    expect(
        tester.getTopLeft(title).dx, greaterThan(tester.getTopRight(emoji).dx));
    expect(tester.getTopLeft(subtitle).dx, tester.getTopLeft(title).dx);
    expect(tester.getTopLeft(subtitle).dy,
        greaterThan(tester.getBottomLeft(title).dy));
    expect(
        tester.getCenter(emoji).dy,
        closeTo(
            (tester.getTopLeft(title).dy + tester.getBottomLeft(subtitle).dy) /
                2,
            0.1));
  });

  testWidgets('image URL is loaded and failure leaves details usable',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ListingDetailsPage(
      listing: listing(imageURL: 'https://example.com/listing.jpg'),
    )));
    final imageRect = tester.getRect(find.byType(Image));
    expect(
        imageRect.top,
        greaterThan(tester
            .getBottomLeft(find.text('Fresh doughnuts made locally.'))
            .dy));
    expect(imageRect.bottom,
        lessThan(tester.getTopLeft(find.text('Get in touch')).dy));
    final image = tester.widget<Image>(find.byType(Image));
    expect(
        (image.image as NetworkImage).url, 'https://example.com/listing.jpg');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
  });

  for (final theme in ['light', 'dark', 'highContrast']) {
    testWidgets('missing image and long text fit narrow screen in $theme theme',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: appThemes[theme],
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: ListingDetailsPage(
              listing: listing(
                  imageURL: '  ',
                  cancelled: true,
                  description:
                      List.filled(20, 'A lovely local listing.').join(' '))),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('CANCELLED'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Telephone'), 300);
      expect(tester.takeException(), isNull);
    });
  }
}
