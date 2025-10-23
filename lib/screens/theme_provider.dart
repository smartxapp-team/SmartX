import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme(); // Load the saved theme when the provider is created
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners(); // Notify widgets to rebuild with the new theme

    // Save the preference
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', mode.name);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode');

    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }
}