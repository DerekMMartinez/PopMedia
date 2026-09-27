// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<void> warmUpVoices() async {
  html.window.speechSynthesis?.getVoices();
}

Future<int> speakWeb(
  String text, {
  required String lang,
  required double rate,
  required double pitch,
  required double volume,
}) async {
  final synth = html.window.speechSynthesis;
  if (synth == null) return 0;

  final utterance = html.SpeechSynthesisUtterance(text)
    ..lang = lang
    ..rate = rate
    ..pitch = pitch
    ..volume = volume;

  final completer = Completer<int>();
  var resolved = false;

  void resolve(int value) {
    if (resolved) return;
    resolved = true;
    completer.complete(value);
  }

  utterance.onStart.first.then((_) => resolve(1));
  utterance.onError.first.then((_) => resolve(0));
  utterance.onEnd.first.then((_) => resolve(1));

  synth.speak(utterance);

  return Future.any<int>([
    completer.future,
    Future<int>.delayed(const Duration(milliseconds: 350), () => 1),
  ]);
}

Future<void> stopWeb() async {
  html.window.speechSynthesis?.cancel();
}
