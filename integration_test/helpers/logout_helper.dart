import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'pump_until.dart';

Future<void> logoutFrom(WidgetTester tester, Key pageKey) async {
  final settings = find.descendant(
    of: find.byKey(pageKey),
    matching: find.byKey(const Key('settings_button_mobile')),
  );

  expect(settings, findsOneWidget);

  await tester.ensureVisible(settings);
  await tester.pumpAndSettle();

  await tester.tap(settings);
  await tester.pumpAndSettle();

  final logoutButton = find.byKey(const Key('logout_button'));
  await pumpUntilFound(tester, logoutButton);

  await tester.tap(logoutButton);
  await tester.pumpAndSettle();
}