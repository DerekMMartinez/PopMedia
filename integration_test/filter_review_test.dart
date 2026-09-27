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

      // Create reviews
      await create_review(tester, 'television', 'Scooby Doo Mystery', 'Scooby-Doo! Mystery Incorporated', 'Scooby Doobie Doo', 'Friends Only');

      await pumpUntilFound(tester, find.byKey(const Key('home_screen')),);
      expect(find.byKey(const Key('home_screen')), findsOneWidget);

      await create_review(tester, 'movie', 'Scre', 'Scream (1996)', "Please don't kill me Mr. Ghostface, I wanna be in the sequel", 'Public');

      await pumpUntilFound(tester, find.byKey(const Key('home_screen')),);
      expect(find.byKey(const Key('home_screen')), findsOneWidget);

      await create_review(tester, 'book', 'The Bell Jar', 'The Bell Jar (2005)', 'Lookin at the fig tree', 'My Eyes Only');

      await pumpUntilFound(tester, find.byKey(const Key('home_screen')),);
      expect(find.byKey(const Key('home_screen')), findsOneWidget);

      final scooby = find.byKey(const Key('my_review_Scooby-Doo! Mystery Incorporated'));
      await pumpUntilFound(tester, scooby);

      final scream = find.byKey(const Key('my_review_Scream (1996)'));
      await pumpUntilFound(tester, scream);

      final tbj = find.byKey(const Key('my_review_The Bell Jar (2005)'));
      await pumpUntilFound(tester, tbj);

      //Check Badge Popup - Earned All 3 Media
      await pumpUntilFound(tester, find.byKey(const Key('badge_earned')),);
      expect(find.byKey(const Key('badge_earned')), findsOneWidget);

      await tester.tap(find.byKey(const Key('close_badge_earned')));
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, find.byKey(const Key('home_screen')),);
      expect(find.byKey(const Key('home_screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('My Reviews_button')));
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, scooby);
      await pumpUntilFound(tester, scream);
      await pumpUntilFound(tester, tbj);

      await tester.tap(find.byKey(const Key('my_reviews_filter')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter_books')));
      await tester.pumpAndSettle();

      expect(tbj, findsOneWidget);
      expect(scooby, findsNothing);
      expect(scream, findsNothing);

      await tester.tap(find.byKey(const Key('my_reviews_filter')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter_movies')));
      await tester.pumpAndSettle();

      expect(tbj, findsNothing);
      expect(scooby, findsNothing);
      expect(scream, findsOneWidget);

      await tester.tap(find.byKey(const Key('my_reviews_filter')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter_tv')));
      await tester.pumpAndSettle();

      expect(tbj, findsNothing);
      expect(scooby, findsOneWidget);
      expect(scream, findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
    
    }finally{
      await delete_review(tester, 'my_review_Scooby-Doo! Mystery Incorporated');
      await delete_review(tester, 'my_review_Scream (1996)');
      await delete_review(tester, 'my_review_The Bell Jar (2005)');

      await pumpUntilFound(tester, find.byKey(const Key('home_screen')),);
      expect(find.byKey(const Key('home_screen')), findsOneWidget);

      await logoutFrom(tester, const Key('home_screen'));
    }
  });
}