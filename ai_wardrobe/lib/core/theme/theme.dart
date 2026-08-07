import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtelierTheme {
  // Brand color tokens — Sage & Cream (English heritage × Korean muted)
  static const Color background = Color(0xFF0C110E);      // Deep forest black
  static const Color surface = Color(0xFF111A14);         // Obsidian sage
  static const Color surfaceAccent = Color(0xFF1A2319);   // Slate sage
  static const Color border = Color(0xFF232B23);          // Sage border
  static const Color accent = Color(0xFFAEC49A);          // Sage
  static const Color accentBright = Color(0xFFE6EAD7);    // Pale cream-sage
  static const Color accentDeep = Color(0xFF6F8255);      // Forest olive
  static const Color primaryText = Color(0xFFECEAD8);     // Warm cream
  static const Color secondaryText = Color(0xFFC6C6AE);   // Soft sage-grey
  static const Color warning = Color(0xFFD98B8B);         // Dusty rose
  static const Color success = Color(0xFF86C79E);         // Sage green

  // Gradient configurations
  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [Color(0xFF111A14), Color(0xFF0C110E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFDDE3C9), Color(0xFF6F8255)], // Cream-sage to forest olive
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
        displayLarge: GoogleFonts.fraunces(
          fontSize: 34,
          fontWeight: FontWeight.w400,
          color: primaryText,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.fraunces(
          fontSize: 26,
          fontWeight: FontWeight.w400,
          color: primaryText,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: primaryText,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primaryText,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          color: secondaryText,
        ),
        labelLarge: GoogleFonts.manrope(
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
