import 'package:flutter/material.dart' hide Theme;
import 'package:pop_media/models/theme.dart';

class ThemeController extends ChangeNotifier {
  Theme currentTheme;
  double _textScale = 1.0;

  ThemeController(this.currentTheme);
  
  double get textScale {
    return _textScale;
  }

  double get minTextScale {
    return 1.0; 
  }

  double get maxTextScale {
    return 1.14; 
  }

  void setTheme(Theme theme) {
    currentTheme = theme;
    notifyListeners();
  }

  void setTextScale(double scale) {
    _textScale = scale.clamp(minTextScale, maxTextScale);
    notifyListeners();
  }
}