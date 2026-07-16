import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtelierTheme {
  // Brand color tokens
  static const Color background = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF161618);
  static const Color surfaceAccent = Color(0xFF222225);
  static const Color border = Color(0xFF2E2E32);
  static const Color accent = Color(0xFF00E676); // Emerald Green
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFF8E8E93);
  static const Color warning = Color(0xFFFF3B30);

  // Gradient configurations
  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [Color(0xFF1E1E24), Color(0xFF0A0A0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      cardColor: surface,
      dividerColor: border,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryText,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primaryText,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: secondaryText,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: secondaryText,
          letterSpacing: 1.0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: accent,
        unselectedItemColor: secondaryText,
        elevation: 0,
      ),
    );
  }
}
