import 'package:flutter/material.dart';

class AppTheme {
  // Method to get theme data from a key
  static ThemeData getThemeData(String key, Brightness platformBrightness) {
    if (key == 'system') {
      return platformBrightness == Brightness.dark ? darkTheme : lightTheme;
    }
    return _themeMap[key] ?? lightTheme; // Default to light theme if key is invalid
  }

  // Maps a theme key to its background asset path
  static String getBackgroundPath(String key, Brightness platformBrightness) {
    if (key == 'system') {
      key = platformBrightness == Brightness.dark ? 'dark' : 'light';
    }
    return _backgroundMap[key] ?? 'assets/light_bg.png';
  }

  // --- PRIVATE --- //

  // Maps a theme key to its ThemeData object
  static final Map<String, ThemeData> _themeMap = {
    'light': lightTheme,
    'dark': darkTheme,
    'light_pastel': pastelTheme,
    'dark_vibrant': vibrantTheme,
    'dark_cool': coolTheme,
  };

  // Maps a theme key to its background asset
  static final Map<String, String> _backgroundMap = {
    'light': 'assets/light_bg.png',
    'dark': 'assets/dark_bg.png',
    'light_pastel': 'assets/bg_light_pastel.png',
    'dark_vibrant': 'assets/bg_dark_vibrant.png',
    'dark_cool': 'assets/bg_dark_cool.png',
  };


  // --- BASE THEMES (Private) ---

  static final ThemeData lightTheme = _createTheme(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF6A5AE0),
    backgroundColor: const Color(0xFFF7F5FF),
    surfaceColor: Colors.white,
    onSurfaceColor: const Color(0xFF1F1D2B),
    secondaryTextColor: Colors.grey,
  );

  static final ThemeData darkTheme = _createTheme(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF7A6BFF),
    backgroundColor: const Color(0xFF1F1D2B),
    surfaceColor: const Color(0xFF252836),
    onSurfaceColor: Colors.white,
    secondaryTextColor: const Color(0xFF9E9E9E),
  );

  static final ThemeData pastelTheme = _createTheme(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFE83D67), // Extracted from image
    backgroundColor: const Color(0xFFFDEBF0), // Light background
    surfaceColor: Colors.white.withOpacity(0.8),
    onSurfaceColor: const Color(0xFF211316),
    secondaryTextColor: Colors.grey.shade600,
  );

  static final ThemeData vibrantTheme = _createTheme(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00FFC2), // Bright cyan/green
    backgroundColor: const Color(0xFF161328),
    surfaceColor: const Color(0xFF2A214A).withOpacity(0.7),
    onSurfaceColor: Colors.white,
    secondaryTextColor: Colors.grey.shade400,
  );

  static final ThemeData coolTheme = _createTheme(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF3887FE), // Bright blue
    backgroundColor: const Color(0xFF121B3A),
    surfaceColor: const Color(0xFF1A2B59).withOpacity(0.7),
    onSurfaceColor: Colors.white,
    secondaryTextColor: Colors.grey.shade400,
  );


  // --- SHARED THEME CREATION LOGIC (Private) ---

  static ThemeData _createTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required Color secondaryTextColor,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent, // Always transparent for background image
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: isDark ? Colors.red.shade200 : Colors.red.shade700,
        onPrimary: isDark ? Colors.black : Colors.white,
        onSecondary: isDark ? Colors.black : Colors.white,
        onSurface: onSurfaceColor,
        onBackground: onSurfaceColor,
        onError: isDark ? Colors.black : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurfaceColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: onSurfaceColor,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: onSurfaceColor),
        titleMedium: TextStyle(color: onSurfaceColor),
        bodyLarge: TextStyle(color: onSurfaceColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: secondaryTextColor),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primaryColor,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        secondaryLabelStyle: TextStyle(color: onSurfaceColor),
        padding: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}
