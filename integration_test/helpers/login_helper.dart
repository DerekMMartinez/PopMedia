import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('email_field')), 'e2e.popmedia@gmail.com');
  await tester.enterText(find.byKey(const Key('pass_field')), 'e2etester');

  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('home_screen')), findsOneWidget);
}