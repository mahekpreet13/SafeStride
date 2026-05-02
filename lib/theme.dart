import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1), // Indigo primary
    brightness: Brightness.dark,
    primary: const Color(0xFF6366F1),
    secondary: const Color(0xFFEC4899), // Pink accent
    tertiary: const Color(0xFF10B981), // Emerald for safety
    surface: const Color(0xFF1E1E2E),
    background: const Color(0xFF0F0F1A),
    onBackground: Colors.white,
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F0F1A),
  cardColor: const Color(0xFF1E1E2E),
  dividerColor: Colors.white10,
  
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 40, letterSpacing: -1.0),
    displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.5),
    displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 17, height: 1.5),
    bodyMedium: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
    labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
  ),
  
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
    ),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      elevation: 8,
      shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E1E2E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600),
    hintStyle: const TextStyle(color: Colors.white24),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  ),
  
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E2E),
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: Colors.white.withOpacity(0.05)),
    ),
  ),
  
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0F0F1A),
    selectedItemColor: Color(0xFF6366F1),
    unselectedItemColor: Colors.white24,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
  ),
);
