import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_until.dart';

Future<void> delete_review(WidgetTester tester,String cardKey) async {
    final card = find.byKey(Key(cardKey));
    await pumpUntilFound(tester, card);

    await tester.tap(card);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete_review_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('review_delete_confirm')));
    await tester.pump();

    await pumpUntilFound(tester, find.byKey(const Key('home_screen')),);
    expect(find.byKey(const Key('home_screen')), findsOneWidget);
}