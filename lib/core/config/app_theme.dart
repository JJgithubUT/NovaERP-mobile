import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores solicitada
  static const Color guindaBase = Color(0xFF73030D);
  static const Color rojoVivo = Color(0xFF9E1A22);
  static const Color fondoPrincipal = Color(0xFFF2F2F2);
  static const Color negroProfundo = Color(0xFF0D0D0D);
  static const Color grisMedio = Color(0xFFAFAFAF);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: fondoPrincipal,
      primaryColor: guindaBase,
      colorScheme: const ColorScheme.light(
        primary: guindaBase,
        secondary: rojoVivo,
        surface: Colors.white,
        background: fondoPrincipal,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: negroProfundo,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: negroProfundo,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: negroProfundo,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: negroProfundo, fontSize: 16),
        bodyMedium: TextStyle(color: grisMedio, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: grisMedio),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: grisMedio),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: guindaBase, width: 2),
        ),
        labelStyle: const TextStyle(color: grisMedio),
      ),
    );
  }
}
