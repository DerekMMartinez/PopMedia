import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TTSController extends ChangeNotifier {
  bool _ttsEnabled = false;

  bool get ttsEnabled => _ttsEnabled;

  TTSController() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _ttsEnabled = prefs.getBool('ttsEnabled') ?? false;
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ttsEnabled', value);

    notifyListeners();
  }
}