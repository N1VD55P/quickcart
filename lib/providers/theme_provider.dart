import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'isDarkMode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = Hive.box('settings');
    _isDarkMode = box.get(_key, defaultValue: false) as bool;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    Hive.box('settings').put(_key, _isDarkMode);
    notifyListeners();
  }
}