import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pop_media/main.dart' as app;
import 'helpers/logout_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login to Tester Account', (tester) async {
    await app.mainCommon(useFirebase: true, fireBaseEmulator: false);
    await tester.pumpAndSettle();

    try {

    const email = 'e2e.popmedia@gmail.com';
    const pass = 'e2etester';

    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('pass_field')), findsOneWidget);
    expect(find.byKey(const Key('login_button')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email_field')), email);
    await tester.enterText(find.byKey(const Key('pass_field')), pass);

    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_screen')), findsOneWidget);
    } finally{
      await logoutFrom(tester, const Key('home_screen'));
    }
  });
}