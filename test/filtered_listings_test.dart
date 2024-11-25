import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';

void main() async {
  // Build widget tree
  Future<void> pumpFilteredListingsPage(
    WidgetTester tester,
    String primaryType,
    List<Map<String, dynamic>> listings,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FilteredListingsPage(
          filterPrimaryType: primaryType,
          listings: listings,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('displays filtered listings correctly', (WidgetTester tester) async {
    // Override user location global
    currentLatLng = const LatLng(52.199174, 0.140929);
    // Define mock values
    listings = [
      {
        'displayName': 'Glazed and Confused',
        'endTime': '16:30',
        'id': '1',
        'phone': '01223 111111',
        'latLng': '52.199687,0.138813',
        'primaryType': 'Food',
        'secondaryType': 'Food',
        'startTime': '10:30',
        'tertiaryType': 'Doughnuts',
        'website': 'https://www.glazedandconfused.com',
      },
      {
        'displayName': 'Sushi Squad',
        'endTime': '16:30',
        'id': '2',
        'phone': '01223 222222',
        'latLng': '52.200063,0.139313',
        'primaryType': 'Food',
        'secondaryType': 'Food',
        'startTime': '12:00',
        'tertiaryType': 'Sushi',
        'website': 'https://www.sushisquad.com',
      },
    ];

    await loadSettings(true);
    await pumpFilteredListingsPage(tester, 'Food', listings);

    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Food • Doughnuts'), findsOneWidget);
    expect(find.text('10:30 - 16:30'), findsOneWidget);
    expect(find.text('approx. 206 m'), findsOneWidget);
    expect(find.text('01223 111111'), findsOneWidget);
    expect(find.text('Sushi Squad'), findsOneWidget);
    expect(find.text('Food • Sushi'), findsOneWidget);
    expect(find.text('12:00 - 16:30'), findsOneWidget);
    expect(find.text('approx. 197 m'), findsOneWidget);
    expect(find.text('01223 222222'), findsOneWidget);
    expect(find.byIcon(Icons.directions), findsExactly(2));
    expect(find.byIcon(Icons.public), findsExactly(2));

    final dividerFinder = find.byWidgetPredicate((widget) => widget is Divider && widget.color == Colors.grey[350]);
    expect(dividerFinder, findsWidgets);
  });
}
