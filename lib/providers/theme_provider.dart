import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A map to hold theme names for the UI
const Map<String, String> themeDisplayNames = {
  'system': 'System Default',
  'light': 'Default Light',
  'dark': 'Default Dark',
  'light_pastel': 'Pastel',
  'dark_vibrant': 'Vibrant',
  'dark_cool': 'Cool',
};

class ThemeProvider with ChangeNotifier {
  String _themeKey = 'system';

  String get themeKey => _themeKey;

  ThemeProvider() {
    _loadTheme();
  }

  // Load the user's saved theme from local storage
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeKey = prefs.getString('theme_key') ?? 'system';
    notifyListeners();
  }

  // Save the user's theme choice to local storage and notify the app
  void setTheme(String themeKey) async {
    _themeKey = themeKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_key', themeKey);
    notifyListeners();
  }
}
