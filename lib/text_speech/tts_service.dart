import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'tts_controller.dart';
import 'tts_web_adapter_stub.dart'
  if (dart.library.html) 'tts_web_adapter_web.dart' as web_tts;

class TtsService {
  final FlutterTts _tts = FlutterTts();
  TTSController _settings;
  bool _initialized = false;
  bool _unlockedByUserGesture = false;
  bool _isSpeaking = false;
  static const String _defaultLang = "en-US";
  static const double _defaultRate = 0.5;
  static const double _defaultVolume = 1.0;
  static const double _defaultPitch = 1.0;

  TtsService(this._settings);

  bool get _requiresUserGestureUnlock =>
      kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void updateSettings(TTSController settings) {
    _settings = settings;
  }

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      await web_tts.warmUpVoices();
    } else {
      await _tts.setLanguage(_defaultLang);
      await _tts.setSpeechRate(_defaultRate);
      await _tts.setVolume(_defaultVolume);
      await _tts.setPitch(_defaultPitch);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });
      _tts.setErrorHandler((_) {
        _isSpeaking = false;
      });
    }

    if (!_requiresUserGestureUnlock) {
      _unlockedByUserGesture = true;
    }

    _initialized = true;
  }

  Future<void> unlockFromUserGesture() async {
    await init();
    _unlockedByUserGesture = true;
  }

  Future<void> speak(String text) async {
    await init();
    if (!_settings.ttsEnabled) return;
    if (_requiresUserGestureUnlock && !_unlockedByUserGesture) return;
    if (text.trim().isEmpty) return;

    if (kIsWeb) {
      await web_tts.speakWeb(
        text,
        lang: _defaultLang,
        rate: _defaultRate,
        pitch: _defaultPitch,
        volume: _defaultVolume,
      );
      return;
    }

    // iOS web can drop speech if cancel/stop is sent right before speak.
    if (!(_requiresUserGestureUnlock)) {
      await _tts.stop();
    } else if (_isSpeaking) {
      await _tts.stop();
    }

    final result = await _tts.speak(text);

    // Retry once on iOS web if the first attempt didn't report success.
    if (_requiresUserGestureUnlock && result != 1) {
      final retryText = text;
      Future.delayed(const Duration(milliseconds: 120), () async {
        await _tts.speak(retryText);
      });
    }
  }

  Future<void> stop() async {
    if (kIsWeb) {
      await web_tts.stopWeb();
      return;
    }
    await _tts.stop();
  }
}