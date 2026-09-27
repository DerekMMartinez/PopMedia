import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pop_media/main.dart' as app;
import 'helpers/login_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Logout Tester Account', (tester) async {
    await app.mainCommon(useFirebase: true, fireBaseEmulator: false);
    await tester.pumpAndSettle();

    await login(tester);

    await tester.tap(find.byKey(const Key('settings_button_mobile')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_page')), findsOneWidget);
  });
}