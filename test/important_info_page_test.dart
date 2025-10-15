import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/important_info_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsPage displays correct initial state', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ImportantInfoPage()));

    // Verify headings
    expect(find.text('Important Information'), findsOneWidget);
    expect(find.text('Stewards'), findsOneWidget);
    expect(find.text('Caution – vehicles!'), findsOneWidget);
    expect(find.text('First Aid'), findsOneWidget);
    expect(find.text('Coming with children?'), findsOneWidget);
    expect(find.text('Road closure'), findsOneWidget);
    expect(find.text('Updates and contact'), findsOneWidget);
  });
}
