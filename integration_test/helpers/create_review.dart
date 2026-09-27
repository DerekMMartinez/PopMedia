import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> create_review(WidgetTester tester,String type, String query, String media_title, String review, String privacy) async {
  await tester.tap(find.byKey(const Key('upload_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('upload_page')), findsOneWidget);

    await tester.tap(find.byKey(Key('media_type_${type}')));

    await tester.enterText(
      find.byKey(const Key('upload_ajax_search')),
      query,
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    final resultFinder = find.text(media_title);
    expect(resultFinder, findsWidgets);

    await tester.tap(resultFinder.first);
    await tester.pumpAndSettle();

    final ratingFinder = find.byKey(const Key('upload_rate'));
    final ratingWidget = tester.getSize(ratingFinder);
    final topLeft = tester.getTopLeft(ratingFinder);

    await tester.tapAt(
      Offset(
        topLeft.dx + ratingWidget.width * 0.9,
        topLeft.dy + ratingWidget.height / 2,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('upload_review')),
      review,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('upload_spoilers')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('privacy_checkbox_${privacy}')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('upload_post_button')));
    await tester.pump();
}