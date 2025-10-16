import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:clutter_zen/screens/auth/sign_in_screen.dart';
import 'package:clutter_zen/screens/auth/phone_otp_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SignIn → Phone route smoke test', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const SignInScreen(),
      routes: {
        '/phone': (_) => const PhoneOtpScreen(),
      },
    ));

    expect(find.text('Welcome Back'), findsOneWidget);
    await tester.tap(find.text('Continue with Phone'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with Phone'), findsOneWidget);
  });
}


