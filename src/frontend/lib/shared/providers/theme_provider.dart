import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark mode as requested

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true; // Default true
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  // App-wide Gradient Background Definitions
  Color get backgroundColor {
    return isDarkMode ? const Color(0xFF0B101E) : const Color(0xFFF0F4F8);
  }

  List<Color> get backgroundGradient {
    return isDarkMode
        ? const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)] // Dark Teal
        : const [Color(0xFFE0EAFC), Color(0xFFCFDEF3)]; // Light Blue/Teal
  }

  // App-wide Glassmorphism Colors
  Color get glassBackgroundColor {
    return isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.white.withOpacity(0.4);
  }

  Color get glassBorderColor {
    return isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.6);
  }

  // Dynamic Text Colors for custom widgets
  Color get primaryTextColor {
    return isDarkMode ? Colors.white : const Color(0xFF2C3E50);
  }
  
  Color get secondaryTextColor {
    return isDarkMode ? Colors.white70 : const Color(0xFF5D6D7E);
  }
}
