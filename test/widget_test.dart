import 'package:flutter_test/flutter_test.dart';

import 'package:one_button_sms/main.dart';

void main() {
  testWidgets('shows the home screen without login', (tester) async {
    await tester.pumpWidget(const OneButtonSmsApp());

    expect(find.text('One Button SMS'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}
