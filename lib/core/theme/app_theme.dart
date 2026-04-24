// lib/core/theme/app_theme.dart
// Updated to match Stitch DESIGN.md token system exactly.
// Light theme uses the "Viberant POS" token set (purple/teal, light surfaces).
// Dark theme uses the "Viberant Logic" token set (deep violet glassmorphic dark).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  LIGHT THEME TOKENS  (from design_system/DESIGN.md)
// ─────────────────────────────────────────────
class ViberantColors {
  // Primary brand — electric indigo
  static const Color primary = Color(0xFF4D41DF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF675DF9);
  static const Color onPrimaryContainer = Color(0xFFFFFBFF);
  static const Color inversePrimary = Color(0xFFC4C0FF);

  // Secondary — teal/green accent
  static const Color secondary = Color(0xFF006B5C);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF68FADE);
  static const Color onSecondaryContainer = Color(0xFF007162);

  // Tertiary — amber/orange
  static const Color tertiary = Color(0xFF914800);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB65C00);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);

  // Surfaces (light)
  static const Color surface = Color(0xFFFCF8FF);
  static const Color surfaceDim = Color(0xFFDCD8E5);
  static const Color surfaceBright = Color(0xFFFCF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F2FF);
  static const Color surfaceContainer = Color(0xFFF0ECF9);
  static const Color surfaceContainerHigh = Color(0xFFEAE6F3);
  static const Color surfaceContainerHighest = Color(0xFFE4E1EE);
  static const Color onSurface = Color(0xFF1B1B24);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color inverseSurface = Color(0xFF302F39);
  static const Color inverseOnSurface = Color(0xFFF3EFFC);
  static const Color surfaceTint = Color(0xFF4F44E2);

  // Outline
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);

  // Semantic
  static const Color success = Color(0xFF006B5C);
  static const Color warning = Color(0xFF914800);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color info = Color(0xFF3B82F6);

  // Backwards-compat aliases used throughout existing screen files
  static const Color background = surfaceContainerLowest;
  static const Color grey = onSurfaceVariant;

  // ─────────────────────────────────────────────
  //  DARK THEME TOKENS  (from viberant_logic/DESIGN.md)
  // ─────────────────────────────────────────────
  static const Color darkPrimary = Color(0xFFCFBCFF);
  static const Color darkOnPrimary = Color(0xFF381E72);
  static const Color darkPrimaryContainer = Color(0xFF6750A4);
  static const Color darkOnPrimaryContainer = Color(0xFFE0D2FF);

  static const Color darkSecondary = Color(0xFFCDC0E9);
  static const Color darkOnSecondary = Color(0xFF342B4B);
  static const Color darkSecondaryContainer = Color(0xFF4D4465);
  static const Color darkOnSecondaryContainer = Color(0xFFBFB2DA);

  static const Color darkTertiary = Color(0xFFE7C365);
  static const Color darkOnTertiary = Color(0xFF3E2E00);
  static const Color darkTertiaryContainer = Color(0xFFC9A74D);
  static const Color darkOnTertiaryContainer = Color(0xFF503D00);

  static const Color darkBackground = Color(0xFF141218);
  static const Color darkSurface = Color(0xFF141218);
  static const Color darkSurfaceDim = Color(0xFF141218);
  static const Color darkSurfaceBright = Color(0xFF3B383E);
  static const Color darkSurfaceContainerLowest = Color(0xFF0F0D13);
  static const Color darkSurfaceContainerLow = Color(0xFF1D1B20);
  static const Color darkSurfaceContainer = Color(0xFF211F24);
  static const Color darkSurfaceContainerHigh = Color(0xFF2B292F);
  static const Color darkSurfaceContainerHighest = Color(0xFF36343A);
  static const Color darkOnSurface = Color(0xFFE6E0E9);
  static const Color darkOnSurfaceVariant = Color(0xFFCBC4D2);
  static const Color darkInverseSurface = Color(0xFFE6E0E9);
  static const Color darkInverseOnSurface = Color(0xFF322F35);
  static const Color darkOutline = Color(0xFF948E9C);
  static const Color darkOutlineVariant = Color(0xFF494551);
  static const Color darkSurfaceTint = Color(0xFFCFBCFF);

  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);

  // Backwards-compat dark aliases
  static const Color darkGrey = darkOnSurfaceVariant;
}

// ─────────────────────────────────────────────
//  TYPOGRAPHY HELPERS
// ─────────────────────────────────────────────
class ViberantTextStyles {
  // Display / headers → Plus Jakarta Sans
  static TextStyle displayXl({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
  );

  static TextStyle headerLg({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: color,
  );

  static TextStyle headerMd({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color,
  );

  // Body / functional → Inter
  static TextStyle bodyLg({Color? color}) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: color,
  );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: color,
  );

  static TextStyle uiLabel({Color? color}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color,
  );

  static TextStyle microCaps({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.6,
    color: color,
  );

  // Wordmark → Poppins (from Viberant Logic)
  static TextStyle wordmark({Color? color}) => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
  );

  static TextStyle wordmarkSuffix({Color? color}) => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w300,
    height: 1.2,
    color: color,
  );
}

// ─────────────────────────────────────────────
//  SHAPE TOKENS
// ─────────────────────────────────────────────
class ViberantRadius {
  static const double sm = 4;
  static const double md = 12;
  static const double card = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double full = 9999;
}

// ─────────────────────────────────────────────
//  ELEVATION / SHADOW TOKENS
// ─────────────────────────────────────────────
class ViberantShadows {
  static List<BoxShadow> get level1 => [
    BoxShadow(
      color: const Color(0xFF4D41DF).withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get level2 => [
    BoxShadow(
      color: const Color(0xFF4D41DF).withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get level4Modal => [
    BoxShadow(
      color: const Color(0xFF4D41DF).withValues(alpha: 0.15),
      blurRadius: 40,
      offset: const Offset(0, 8),
    ),
  ];
}

// ─────────────────────────────────────────────
//  THEME DATA
// ─────────────────────────────────────────────
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ViberantColors.primary,
      scaffoldBackgroundColor: ViberantColors.surfaceContainerLowest,
      colorScheme: const ColorScheme.light(
        primary: ViberantColors.primary,
        onPrimary: ViberantColors.onPrimary,
        primaryContainer: ViberantColors.primaryContainer,
        onPrimaryContainer: ViberantColors.onPrimaryContainer,
        secondary: ViberantColors.secondary,
        onSecondary: ViberantColors.onSecondary,
        secondaryContainer: ViberantColors.secondaryContainer,
        onSecondaryContainer: ViberantColors.onSecondaryContainer,
        tertiary: ViberantColors.tertiary,
        onTertiary: ViberantColors.onTertiary,
        tertiaryContainer: ViberantColors.tertiaryContainer,
        onTertiaryContainer: ViberantColors.onTertiaryContainer,
        surface: ViberantColors.surface,
        surfaceContainerLowest: ViberantColors.surfaceContainerLowest,
        surfaceContainerLow: ViberantColors.surfaceContainerLow,
        surfaceContainer: ViberantColors.surfaceContainer,
        surfaceContainerHigh: ViberantColors.surfaceContainerHigh,
        surfaceContainerHighest: ViberantColors.surfaceContainerHighest,
        onSurface: ViberantColors.onSurface,
        onSurfaceVariant: ViberantColors.onSurfaceVariant,
        inverseSurface: ViberantColors.inverseSurface,
        onInverseSurface: ViberantColors.inverseOnSurface,
        inversePrimary: ViberantColors.inversePrimary,
        outline: ViberantColors.outline,
        outlineVariant: ViberantColors.outlineVariant,
        error: ViberantColors.error,
        onError: ViberantColors.onError,
        errorContainer: ViberantColors.errorContainer,
        onErrorContainer: ViberantColors.onErrorContainer,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: _buildTextTheme(ViberantColors.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: ViberantColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: ViberantColors.outlineVariant,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ViberantColors.onSurfaceVariant),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: ViberantColors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: ViberantColors.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ViberantColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ViberantColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: const BorderSide(color: ViberantColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: const BorderSide(color: ViberantColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: const BorderSide(color: ViberantColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.inter(
          color: ViberantColors.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(
          color: ViberantColors.onSurfaceVariant,
          fontSize: 14,
        ),
        errorStyle: GoogleFonts.inter(
          color: ViberantColors.error,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ViberantColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ViberantRadius.card),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ViberantColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ViberantColors.primary,
          side: const BorderSide(color: ViberantColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ViberantRadius.card),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ViberantColors.surfaceContainerLow,
        selectedColor: ViberantColors.primary.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.full),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: ViberantColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ViberantColors.surfaceContainerLowest,
        selectedItemColor: ViberantColors.primary,
        unselectedItemColor: ViberantColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ViberantColors.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          color: ViberantColors.inverseOnSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ViberantColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.lg),
        ),
        elevation: 3,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ViberantColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ViberantRadius.lg),
          ),
        ),
        elevation: 0,
        modalElevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: ViberantColors.darkPrimary,
      scaffoldBackgroundColor: ViberantColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: ViberantColors.darkPrimary,
        onPrimary: ViberantColors.darkOnPrimary,
        primaryContainer: ViberantColors.darkPrimaryContainer,
        onPrimaryContainer: ViberantColors.darkOnPrimaryContainer,
        secondary: ViberantColors.darkSecondary,
        onSecondary: ViberantColors.darkOnSecondary,
        secondaryContainer: ViberantColors.darkSecondaryContainer,
        onSecondaryContainer: ViberantColors.darkOnSecondaryContainer,
        tertiary: ViberantColors.darkTertiary,
        onTertiary: ViberantColors.darkOnTertiary,
        tertiaryContainer: ViberantColors.darkTertiaryContainer,
        onTertiaryContainer: ViberantColors.darkOnTertiaryContainer,
        surface: ViberantColors.darkSurface,
        surfaceContainerLowest: ViberantColors.darkSurfaceContainerLowest,
        surfaceContainerLow: ViberantColors.darkSurfaceContainerLow,
        surfaceContainer: ViberantColors.darkSurfaceContainer,
        surfaceContainerHigh: ViberantColors.darkSurfaceContainerHigh,
        surfaceContainerHighest: ViberantColors.darkSurfaceContainerHighest,
        onSurface: ViberantColors.darkOnSurface,
        onSurfaceVariant: ViberantColors.darkOnSurfaceVariant,
        inverseSurface: ViberantColors.darkInverseSurface,
        onInverseSurface: ViberantColors.darkInverseOnSurface,
        inversePrimary: ViberantColors.darkPrimary,
        outline: ViberantColors.darkOutline,
        outlineVariant: ViberantColors.darkOutlineVariant,
        error: ViberantColors.darkError,
        onError: ViberantColors.darkOnError,
        errorContainer: ViberantColors.darkErrorContainer,
        onErrorContainer: ViberantColors.darkOnErrorContainer,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: _buildTextTheme(ViberantColors.darkOnSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: ViberantColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: ViberantColors.darkOutlineVariant,
        centerTitle: false,
        iconTheme: const IconThemeData(
          color: ViberantColors.darkOnSurfaceVariant,
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: ViberantColors.darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: ViberantColors.darkSurfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ViberantColors.darkPrimary,
        foregroundColor: ViberantColors.darkOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ViberantColors.darkSurfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: const BorderSide(
            color: ViberantColors.darkOutlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: const BorderSide(
            color: ViberantColors.darkPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: const BorderSide(
            color: ViberantColors.darkError,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: const BorderSide(
            color: ViberantColors.darkError,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.inter(
          color: ViberantColors.darkOnSurfaceVariant,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: ViberantColors.darkOnSurfaceVariant,
          fontSize: 14,
        ),
        errorStyle: GoogleFonts.inter(
          color: ViberantColors.darkError,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ViberantColors.darkPrimary,
          foregroundColor: ViberantColors.darkOnPrimary,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ViberantRadius.card),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ViberantColors.darkPrimary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ViberantColors.darkPrimary,
          side: const BorderSide(color: ViberantColors.darkOutline, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ViberantRadius.card),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ViberantColors.darkSurfaceContainerHigh,
        selectedColor: ViberantColors.darkPrimary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ViberantColors.darkOnSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.full),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: ViberantColors.darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ViberantColors.darkSurfaceContainerLow,
        selectedItemColor: ViberantColors.darkPrimary,
        unselectedItemColor: ViberantColors.darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ViberantColors.darkSurfaceContainerHighest,
        contentTextStyle: GoogleFonts.inter(
          color: ViberantColors.darkOnSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ViberantColors.darkSurfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.lg),
        ),
        elevation: 3,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ViberantColors.darkSurfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ViberantRadius.lg),
          ),
        ),
        elevation: 0,
        modalElevation: 0,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: baseColor,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: baseColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: baseColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: baseColor.withValues(alpha: 0.8),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0.6,
        color: baseColor.withValues(alpha: 0.8),
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.0,
        letterSpacing: 0.4,
        color: baseColor.withValues(alpha: 0.6),
      ),
    );
  }
}
