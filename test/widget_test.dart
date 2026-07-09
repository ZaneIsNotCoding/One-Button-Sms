import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_button_sms/main.dart';

void main() {
  testWidgets('shows SMS and Contact SOS buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const OneButtonSmsApp());

    expect(find.text('One Button SMS'), findsOneWidget);
    expect(find.text('Ready to send'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Send SMS'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Contact SOS'), findsOneWidget);
    expect(find.text('0 added contact(s)'), findsOneWidget);
  });

  testWidgets('opens contacts page when Contact SOS has no contacts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OneButtonSmsApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Contact SOS'));
    await tester.pumpAndSettle();

    expect(find.text('No contacts added yet.'), findsOneWidget);
    expect(
      find.widgetWithText(FloatingActionButton, 'Add Contact'),
      findsOneWidget,
    );
  });

  testWidgets('adds a contact and uses Contact SOS', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OneButtonSmsApp());

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Contact'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Mother');
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone number'),
      '09123456789',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Mother'), findsOneWidget);
    expect(find.text('09123456789'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('1 added contact(s)'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Contact SOS'));
    await tester.pump();

    expect(find.text('Contact SOS ready for 1 contact(s)'), findsOneWidget);
  });
}
