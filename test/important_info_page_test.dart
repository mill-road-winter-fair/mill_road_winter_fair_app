import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsPage displays correct initial state', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ImportantInfoPage()));

    // Verify headings
    expect(find.text('Important Info'), findsOneWidget);
    expect(find.text('Stewards'), findsOneWidget);
    expect(find.text('Caution – Vehicles!'), findsOneWidget);
    expect(find.text('First Aid'), findsOneWidget);
    expect(find.text('Missing Children'), findsOneWidget);
    expect(find.text('Toilets'), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
  });
}
