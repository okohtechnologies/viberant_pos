// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViberantColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF4A44B8);
  static const Color accent = Color(0xFF00BFA6);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF2D3748);
  static const Color grey = Color(0xFF718096);

  static Color? get info => null;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // Enable Material 3 for modern styling
      primaryColor: ViberantColors.primary,
      scaffoldBackgroundColor: ViberantColors.background,
      colorScheme: ColorScheme.light(
        primary: ViberantColors.primary,
        secondary: ViberantColors.secondary,
        surface: ViberantColors.surface,
        onSurface: ViberantColors.onSurface,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,

      // AppBar styling
      appBarTheme: AppBarTheme(
        backgroundColor: ViberantColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: ViberantColors.onSurface),
        titleTextStyle: GoogleFonts.poppins(
          color: ViberantColors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ViberantColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Card styling

      // Input decoration (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ViberantColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ViberantColors.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ElevatedButton styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ViberantColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton styling
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ViberantColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton styling
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ViberantColors.primary,
          side: BorderSide(color: ViberantColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
