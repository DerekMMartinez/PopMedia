import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pop_media/main.dart' as app;
import 'helpers/create_review.dart';
import 'helpers/delete_review.dart';
import 'helpers/login_helper.dart';
import 'helpers/logout_helper.dart';
import 'helpers/pump_until.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CRUD: Reviews', (tester) async {
    await app.mainCommon(useFirebase: true, fireBaseEmulator: false);
    await tester.pumpAndSettle();

    try {
      await login(tester);

      //Exit Page Working
      await tester.tap(find.byKey(const Key('upload_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('upload_page')), findsOneWidget);

      await tester.tap(find.byKey(const Key('exit_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('leave_button')));
      await tester.pumpAndSettle();

      // Create review
      await create_review(tester, 'television', 'Scooby Doo Mystery', 'Scooby-Doo! Mystery Incorporated', 'Scooby Doobie Doo', 'Friends Only');

      //Edit Review
      await pumpUntilFound(tester, find.byKey(const Key('home_screen')),);
      expect(find.byKey(const Key('home_screen')), findsOneWidget);

      final card = find.byKey(const Key('my_review_Scooby-Doo! Mystery Incorporated'));
      await pumpUntilFound(tester, card);

      await tester.tap(card);
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, find.byKey(const Key('single_review_page')),);
      expect(find.byKey(const Key('single_review_page')), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_spoilers')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, find.byKey(const Key('home_screen')),);
      expect(find.byKey(const Key('home_screen')), findsOneWidget);
    } finally {

      //Delete Review
      await delete_review(tester, 'my_review_Scooby-Doo! Mystery Incorporated');

      await logoutFrom(tester, const Key('home_screen'));
    }
  });
}