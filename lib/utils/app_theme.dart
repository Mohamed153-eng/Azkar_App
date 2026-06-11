// lib/utils/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Colours ────────────────────────────────────────────
  static const Color primary      = Color(0xFF1A6B5A); // Deep teal-green
  static const Color primaryLight = Color(0xFF2E9474);
  static const Color primaryDark  = Color(0xFF0F4A3E);
  static const Color accent       = Color(0xFFD4A852); // Warm gold
  static const Color accentLight  = Color(0xFFE8C577);
  static const Color bg           = Color(0xFF0D1F1A); // Very dark green
  static const Color surface      = Color(0xFF142B24); // Card bg
  static const Color surfaceLight = Color(0xFF1C3B32);
  static const Color textPrimary  = Color(0xFFF0EAD6); // Warm cream
  static const Color textSecondary= Color(0xFFA8B9B4);
  static const Color textHint     = Color(0xFF6B8880);
  static const Color success      = Color(0xFF4CAF7D);
  static const Color divider      = Color(0xFF1F3D33);

  // Category colours
  static const Color morningColor = Color(0xFFE8A020); // Sunrise orange-gold
  static const Color eveningColor = Color(0xFF6A7FDB); // Twilight purple-blue
  static const Color sleepColor   = Color(0xFF4A7FAA); // Night blue
  static const Color customColor  = Color(0xFF70B87E); // Soft green

  static Color categoryColor(String cat) {
    switch (cat) {
      case 'morning': return morningColor;
      case 'evening': return eveningColor;
      case 'sleep':   return sleepColor;
      default:        return customColor;
    }
  }

  // ── Typography ─────────────────────────────────────────
  static TextTheme _buildTextTheme() {
    // Amiri for body Arabic text, Tajawal for UI
    return TextTheme(
      displayLarge: GoogleFonts.amiri(
        fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, height: 1.8,
      ),
      displayMedium: GoogleFonts.amiri(
        fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary, height: 1.8,
      ),
      headlineLarge: GoogleFonts.tajawal(
        fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      headlineMedium: GoogleFonts.tajawal(
        fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      headlineSmall: GoogleFonts.tajawal(
        fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      titleLarge: GoogleFonts.tajawal(
        fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      titleMedium: GoogleFonts.tajawal(
        fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary,
      ),
      bodyLarge: GoogleFonts.amiri(
        fontSize: 20, color: textPrimary, height: 1.9,
      ),
      bodyMedium: GoogleFonts.tajawal(
        fontSize: 14, color: textSecondary, height: 1.6,
      ),
      bodySmall: GoogleFonts.tajawal(
        fontSize: 12, color: textHint, height: 1.5,
      ),
      labelLarge: GoogleFonts.tajawal(
        fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary,
      ),
    );
  }

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary:    primary,
      secondary:  accent,
      surface:    surface,
      onPrimary:  textPrimary,
      onSurface:  textPrimary,
    ),
    scaffoldBackgroundColor: bg,
    textTheme: _buildTextTheme(),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.tajawal(
        fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: accent,
      unselectedItemColor: textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryLight, width: 1.5),
      ),
      labelStyle: GoogleFonts.tajawal(color: textSecondary),
      hintStyle: GoogleFonts.tajawal(color: textHint),
    ),
  );
}
