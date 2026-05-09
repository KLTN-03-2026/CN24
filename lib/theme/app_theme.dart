import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF1C64F2);
  
  // Light Theme Colors
  static const lightBg = Color(0xFFF8FAFC);
  static const lightTextDark = Color(0xFF0F172A);
  static const lightTextSoft = Color(0xFF64748B);
  static const lightCard = Colors.white;

  // Dark Theme Colors
  static const darkBg = Color(0xFF0F172A);
  static const darkTextLight = Color(0xFFF8FAFC);
  static const darkTextSoft = Color(0xFF94A3B8);
  static const darkCard = Color(0xFF1E293B);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBg,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      surface: lightCard,
      onSurface: lightTextDark,
      onSurfaceVariant: lightTextSoft,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: lightTextDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: lightTextDark),
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: lightTextDark, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: lightTextDark),
      bodyMedium: TextStyle(color: lightTextSoft),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBg,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      surface: darkCard,
      onSurface: darkTextLight,
      onSurfaceVariant: darkTextSoft,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: darkTextLight,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: darkTextLight),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: darkTextLight, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: darkTextLight),
      bodyMedium: TextStyle(color: darkTextSoft),
    ),
  );
}
