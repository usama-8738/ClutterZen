import 'package:clutter_zen/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyApp renders without crashing', (tester) async {
    await tester.pumpWidget(
        const MyApp(enableAuthGate: false, initialRoute: '/pricing'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // App should boot into Material context and show a Navigator.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
  });
}
