import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgriTheme {
  // --- Color Palette: Deep Earth & Harvest ---
  // Deep, rich greens and earthy browns for a premium, non-generic look.
  // Avoiding standard Material colors.
  static const Color _primary = Color(0xFF1B4D3E); // Deep Forest Green
  static const Color _secondary = Color(0xFFA67C52); // Rich Soil Brown
  static const Color _accent = Color(0xFFD4AF37); // Golden Harvest
  static const Color _background =
      Color(0xFFF5F2EB); // Warm Parchment/Off-white
  static const Color _surface = Color(0xFFFFFFFF); // Clean White for cards
  static const Color _textPrimary = Color(0xFF1A1A1A); // Almost Black
  static const Color _textSecondary = Color(0xFF5A5A5A); // Dark Grey

  static final ThemeData themeData = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: _background,
    brightness: Brightness.light,

    // --- Typography (Expressive & Bold) ---
    textTheme: TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        // Headings with personality
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
      titleLarge: GoogleFonts.dmSans(
        // Clean, modern body font
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        color: _textSecondary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        color: _textSecondary,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: _surface,
      ),
    ),

    // --- Component Themes ---
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      tertiary: _accent,
      surface: _surface,
      onPrimary: _surface,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: _background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: _textPrimary),
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: _surface,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: _surface,
      elevation: 2, // Slight elevation for depth
      shadowColor: _primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            12), // Slightly less rounded for "professional" look
        side: BorderSide(color: _secondary.withOpacity(0.2), width: 1),
      ),
      margin: EdgeInsets.zero, // Remove default margin hindrance
      clipBehavior: Clip.antiAlias,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _secondary.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _secondary.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      labelStyle: TextStyle(color: _textSecondary, fontWeight: FontWeight.w500),
      hintStyle: GoogleFonts.dmSans(color: Colors.grey[500]),
    ),
  );
}
