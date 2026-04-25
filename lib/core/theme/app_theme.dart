import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VIBERANT COLOR SYSTEM — aligned to Google Stitch output
// ─────────────────────────────────────────────────────────────────────────────
class ViberantColors {
  // Brand
  static const Color primary = Color(0xFF4D41DF);
  static const Color primaryContainer = Color(0xFF675DF9);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF006B5C);
  static const Color secondaryContainer = Color(0xFF68FADE);
  static const Color accent = Color(0xFF00BFA6);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFBA1A1A);
  static const Color info = Color(0xFF3B82F6);

  // Light surfaces (Stitch warm lavender system)
  static const Color background = Color(0xFFFCF8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F2FF);
  static const Color surfaceContainer = Color(0xFFF0ECF9);
  static const Color surfaceContainerHigh = Color(0xFFEAE6F3);
  static const Color surfaceContainerHighest = Color(0xFFE4E1EE);
  static const Color onSurface = Color(0xFF1B1B24);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);

  // Dark surfaces (Stitch viberant_logic system)
  static const Color darkBackground = Color(0xFF141218);
  static const Color darkSurface = Color(0xFF1D1B20);
  static const Color darkSurfaceContainer = Color(0xFF211F24);
  static const Color darkOnSurface = Color(0xFFE6E0E9);
  static const Color darkOnSurfaceVariant = Color(0xFFCBC4D2);
  static const Color darkOutline = Color(0xFF948E9C);
  static const Color darkOutlineVariant = Color(0xFF494551);

  // Alias
  static const Color grey = outline;
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME BUILDER
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ViberantColors.primary,
      scaffoldBackgroundColor: ViberantColors.background,
      colorScheme: const ColorScheme.light(
        primary: ViberantColors.primary,
        onPrimary: ViberantColors.onPrimary,
        primaryContainer: ViberantColors.primaryContainer,
        secondary: ViberantColors.secondary,
        secondaryContainer: ViberantColors.secondaryContainer,
        surface: ViberantColors.surface,
        surfaceContainerLow: ViberantColors.surfaceContainerLow,
        surfaceContainer: ViberantColors.surfaceContainer,
        surfaceContainerHigh: ViberantColors.surfaceContainerHigh,
        surfaceContainerHighest: ViberantColors.surfaceContainerHighest,
        onSurface: ViberantColors.onSurface,
        onSurfaceVariant: ViberantColors.onSurfaceVariant,
        outline: ViberantColors.outline,
        outlineVariant: ViberantColors.outlineVariant,
        error: ViberantColors.error,
        onError: ViberantColors.onPrimary,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: ViberantColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: ViberantColors.outlineVariant.withOpacity(0.3),
        centerTitle: false,
        iconTheme: const IconThemeData(color: ViberantColors.onSurface),
        titleTextStyle: GoogleFonts.poppins(
          color: ViberantColors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: ViberantColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: ViberantColors.outlineVariant.withOpacity(0.4),
            width: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ViberantColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ViberantColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ViberantColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ViberantColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ViberantColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(
          color: ViberantColors.outline,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: ViberantColors.onSurfaceVariant,
          fontSize: 14,
        ),
        prefixIconColor: ViberantColors.outline,
        suffixIconColor: ViberantColors.outline,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ViberantColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ViberantColors.primary.withOpacity(0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ViberantColors.primary,
          side: const BorderSide(color: ViberantColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ViberantColors.primary,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ViberantColors.surfaceContainerHigh,
        selectedColor: ViberantColors.primary.withOpacity(0.12),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      dividerTheme: DividerThemeData(
        color: ViberantColors.outlineVariant.withOpacity(0.5),
        thickness: 0.5,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ViberantColors.surface,
        selectedItemColor: ViberantColors.primary,
        unselectedItemColor: ViberantColors.outline,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: ViberantColors.onSurface,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ViberantColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ViberantColors.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: ViberantColors.onSurfaceVariant,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFCFBCFF),
      scaffoldBackgroundColor: ViberantColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFCFBCFF),
        onPrimary: Color(0xFF381E72),
        primaryContainer: Color(0xFF6750A4),
        secondary: Color(0xFFCDC0E9),
        surface: ViberantColors.darkSurface,
        surfaceContainer: ViberantColors.darkSurfaceContainer,
        onSurface: ViberantColors.darkOnSurface,
        onSurfaceVariant: ViberantColors.darkOnSurfaceVariant,
        outline: ViberantColors.darkOutline,
        outlineVariant: ViberantColors.darkOutlineVariant,
        error: Color(0xFFFFB4AB),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: ViberantColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ViberantColors.darkOnSurface),
        titleTextStyle: GoogleFonts.poppins(
          color: ViberantColors.darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: ViberantColors.darkSurfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: ViberantColors.darkOutlineVariant.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ViberantColors.darkSurfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCFBCFF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(color: ViberantColors.darkOutline),
        labelStyle: GoogleFonts.inter(
          color: ViberantColors.darkOnSurfaceVariant,
        ),
        prefixIconColor: ViberantColors.darkOutline,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ViberantColors.darkOutlineVariant,
        thickness: 0.5,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ViberantColors.darkSurface,
        selectedItemColor: const Color(0xFFCFBCFF),
        unselectedItemColor: ViberantColors.darkOutline,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
      ),
    );
  }
}
