import 'package:flutter/material.dart';

class AppTheme {
  // 🌞 Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1E88E5),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    fontFamily: 'Poppins',

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E88E5),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color.fromRGBO(255, 255, 255, 0.95),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.black45),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // ListTile styling
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF1E88E5),
      textColor: Colors.black87,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    ),
  );

  // 🌙 Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1E88E5),
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E88E5),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color.fromRGBO(30, 30, 30, 0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF1E88E5),
      textColor: Colors.white70,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    ),
  );

  /// 🌟 Subtle Background Gradient
  static BoxDecoration backgroundGradient(bool isDarkMode) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: isDarkMode
            ? [Color(0xFF121212), Color(0xFF1A1A1A)]
            : [Color(0xFFF5F7FA), Color(0xFFE8EDF3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  /// Use this method to create "Card-style" containers safely
  static Widget cardContainer({
    required Widget child,
    bool isDarkMode = false,
    EdgeInsetsGeometry margin = const EdgeInsets.all(8),
    double borderRadius = 16,
    double elevation = 4,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Color.fromRGBO(30, 30, 30, 0.92)
            : Color.fromRGBO(255, 255, 255, 0.97),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black45 : Colors.black12,
            blurRadius: elevation,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
