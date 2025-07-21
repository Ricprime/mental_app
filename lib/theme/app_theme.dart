// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Paleta de Colores Principal ---
  // Usaremos un azul más calmado y profesional que el 'blueAccent' por defecto.
  static const Color primaryColor = Color(0xFF4A90E2); // Un azul sereno
  static const Color secondaryColor = Color(0xFF50E3C2); // Un acento turquesa
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF333333);

  // --- Tema Claro Unificado ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,

    // Esquema de color basado en nuestro color primario.
    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),

    // Tipografía base para toda la app usando Google Fonts.
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),

    // Tema para la AppBar (barra superior).
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor, // Fondo consistente con la pantalla.
      elevation: 0,
      iconTheme: const IconThemeData(color: textColor),
      titleTextStyle: GoogleFonts.poppins(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Tema para los ElevatedButtons (botones con fondo).
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Usamos nuestro color primario.
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // Tema para los OutlinedButtons (botones con borde).
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor, // Usamos nuestro color primario.
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // Tema para los campos de entrada de texto (TextField, TextFormField).
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade600),
    ),
  );
}