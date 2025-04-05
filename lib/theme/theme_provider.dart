import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  late ThemeData _currentTheme;

  // Soft colors for dark mode
  static final Color _darkBackground = Color(0xFF1E1E1E);
  static final Color _darkSurface = Color(0xFF252525);
  static final Color _darkPrimary = Color(0xFF689F38); // A soft green
  static final Color _darkSecondary = Color(0xFF4E8098); // A soft blue
  static final Color _darkText = Color(0xFFE0E0E0); // Soft white/grey

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;
  bool get isDarkMode => _isDarkMode;

  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      color: Colors.green,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.white,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    iconTheme: IconThemeData(
      color: Colors.black87,
    ),
  );

  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    primaryColor: _darkPrimary,
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: AppBarTheme(
      color: _darkSurface,
      iconTheme: IconThemeData(color: _darkText),
    ),
    cardTheme: CardTheme(
      color: _darkSurface,
      elevation: 2,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: _darkBackground,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: _darkText),
      bodyMedium: TextStyle(color: _darkText),
    ),
    iconTheme: IconThemeData(
      color: _darkText,
    ),
    dialogBackgroundColor: _darkSurface,
    dividerColor: Colors.grey.shade700,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimary,
      secondary: _darkSecondary,
      surface: _darkSurface,
      background: _darkBackground,
      onBackground: _darkText,
      onSurface: _darkText,
    ),
  );

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
      _isDarkMode = false;
    }
  }

  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }
}
