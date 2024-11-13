import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mill_road_winter_fair_app/filtered_listings.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@GenerateMocks([http.Client])
import 'filtered_listings_test.mocks.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  mrwfApi = dotenv.env['MRWF_API'] ?? '';

  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
  });

  Future<void> pumpFilteredListingsPage(
    WidgetTester tester,
    String primaryType,
    String secondaryType,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FilteredListingsPage(
          filterPrimaryType: primaryType,
          filterSecondaryType: secondaryType,
          client: mockClient,
        ),
      ),
    );
    await tester.pump(); // Start initial build.
    await tester.pumpAndSettle(); // Wait for FutureBuilder to resolve.
  }

  testWidgets('displays error text when fetchFilteredListings fails',
      (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('$mrwfApi/listings')))
        .thenAnswer((_) async => http.Response('', 500));

    await pumpFilteredListingsPage(tester, 'Vendor', 'Food');

    expect(find.text('Error fetching listings'), findsOneWidget);
  });

  testWidgets('displays filtered listings correctly',
      (WidgetTester tester) async {
    final listings = [
      {
        'displayName': 'Glazed and Confused',
        'secondaryType': 'Food',
        'tertiaryType': 'Doughnuts',
        'startTime': '09:00',
        'endTime': '15:00',
        'phone': '01234 567890',
        'primaryType': 'Vendor',
        'website': 'https://glazed.com',
        'id': 1,
        'plusCode': '9F4254XQ+VG',
      },
    ];

    when(mockClient.get(Uri.parse('$mrwfApi/listings'))).thenAnswer(
      (_) async => http.Response(jsonEncode(listings), 200),
    );

    await pumpFilteredListingsPage(tester, 'Vendor', 'Food');

    expect(find.text('Glazed and Confused'), findsOneWidget);
    expect(find.text('Food • Doughnuts'), findsOneWidget);
    expect(find.text('09:00 - 15:00'), findsOneWidget);
  });
}
