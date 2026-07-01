import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_button_sms/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('one_button_sms/device');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'requestPermissions':
          return true;
        case 'getLocation':
          return {'latitude': 14.5995, 'longitude': 120.9842};
        case 'sendSms':
          return 1;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('shows the home screen without login', (tester) async {
    await tester.pumpWidget(const OneButtonSmsApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('SOS'), findsWidgets);
    expect(find.text('PNP'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });
}
