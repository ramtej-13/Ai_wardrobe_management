import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtelierTheme {
  // Brand color tokens (Ice & Orchid Cyber-Luxury Palette)
  static const Color background = Color(0xFF030304);      // Void Black
  static const Color surface = Color(0xFF0D0D12);         // Space Obsidian
  static const Color surfaceAccent = Color(0xFF16161F);   // Slate Obsidian
  static const Color border = Color(0xFF1E1E28);          // Slate Border
  static const Color accent = Color(0xFF8DF7FF);          // Ice Neon Cyan
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFF8F8F9F);   // Cool Grey
  static const Color warning = Color(0xFFFE4A49);         // Crimson Red

  // Gradient configurations
  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [Color(0xFF0E0E14), Color(0xFF030304)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8DF7FF), Color(0xFFD980FF)], // Ice Cyan to Orchid Violet
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
