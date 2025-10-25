import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/main.dart';

void main() {
  testWidgets('emailDetailsDialog shows emails and close button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

    // show the dialog
    showDialog(context: tester.element(find.byType(SizedBox)), builder: (context) => contactUsDialog());
    await tester.pumpAndSettle();

    // Check for some known email addresses
    expect(find.text('info@millroadwinterfair.org'), findsOneWidget);
    expect(find.text('volunteers@millroadwinterfair.org'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Tap Close button and verify dialog is dismissed
    final close = find.text("Close");
    await tester.dragUntilVisible(
      close,
      find.byType(SingleChildScrollView),
      const Offset(0, 50),
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('info@millroadwinterfair.org'), findsNothing);
  });
}
