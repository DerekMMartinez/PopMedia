import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }

  throw TimeoutException('Timed out waiting for $finder');
}