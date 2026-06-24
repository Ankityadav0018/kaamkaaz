import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ─────────────────────────────────────────────────────────
//  App theme modes
// ─────────────────────────────────────────────────────────
enum AppThemeMode {
  light,    // White / soft-gray
  dark,     // Deep navy / black (default)
  midnight, // Pure black with purple accents
}

extension AppThemeModeExt on AppThemeMode {
  String get key => name; // stored key in SharedPreferences
  String get label {
    switch (this) {
      case AppThemeMode.light:    return 'Light';
      case AppThemeMode.dark:     return 'Dark';
      case AppThemeMode.midnight: return 'Midnight';
    }
  }
  // Swatch preview colors
  Color get bg {
    switch (this) {
      case AppThemeMode.light:    return const Color(0xFFF8FAFC);
      case AppThemeMode.dark:     return const Color(0xFF0D2155);
      case AppThemeMode.midnight: return const Color(0xFF0A0014);
    }
  }
  Color get accent {
    switch (this) {
      case AppThemeMode.light:    return AppColors.primary;
      case AppThemeMode.dark:     return AppColors.primaryLight;
      case AppThemeMode.midnight: return const Color(0xFFBB86FC); // purple
    }
  }
  Color get card {
    switch (this) {
      case AppThemeMode.light:    return Colors.white;
      case AppThemeMode.dark:     return const Color(0xFF1A3A7A);
      case AppThemeMode.midnight: return const Color(0xFF1A0033);
    }
  }
  String get icon {
    switch (this) {
      case AppThemeMode.light:    return '☀️';
      case AppThemeMode.dark:     return '🌙';
      case AppThemeMode.midnight: return '🔮';
    }
  }
}

// ─────────────────────────────────────────────────────────
//  Midnight accent (purple)
// ─────────────────────────────────────────────────────────
const _midnightAccent  = Color(0xFFBB86FC);
const _midnightPrimary = Color(0xFF9B51E0);
const _midnightBg      = Color(0xFF0A0014);
const _midnightCard    = Color(0xFF1A0033);
const _midnightSurface = Color(0xFF12002A);

// ─────────────────────────────────────────────────────────
//  Helper: build a shared text theme
// ─────────────────────────────────────────────────────────
TextTheme _textTheme(Color primary, Color secondary) {
  return GoogleFonts.notoSansTextTheme().copyWith(
    displayLarge: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: primary),
    displayMedium: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: primary),
    titleLarge: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: primary),
    bodyLarge: GoogleFonts.notoSans(fontSize: 13.5, height: 1.5, color: secondary),
    bodyMedium: GoogleFonts.notoSans(fontSize: 12.5, height: 1.5, color: secondary),
    labelLarge: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: secondary),
  );
}

// ─────────────────────────────────────────────────────────
//  AppTheme — factory
// ─────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData themeFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:    return lightTheme;
      case AppThemeMode.dark:     return darkTheme;
      case AppThemeMode.midnight: return midnightTheme;
    }
  }

  // ── Light ───────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgWhite,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: _textTheme(AppColors.textDark, AppColors.textMedium),
      appBarTheme: const AppBarTheme(
        elevation: 0, centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54), elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.danger, width: 1)),
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.textMedium),
        floatingLabelStyle: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white, selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed, elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary, unselectedLabelColor: AppColors.textMedium,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.primary, width: 3)),
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)), side: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      dividerTheme: const DividerThemeData(thickness: 1, color: Color(0xFFF0F0F0), space: 1),
    );
  }

  // ── Dark (Navy / black) ──────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: const Color(0xFF1E2A4A),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF060E2A),
      textTheme: _textTheme(Colors.white, Colors.white70),
      appBarTheme: const AppBarTheme(
        elevation: 0, centerTitle: true,
        backgroundColor: Color(0xFF0D1F45),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54), elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight, minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFF162040),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A3F6E), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.danger, width: 1)),
        labelStyle: const TextStyle(fontSize: 14, color: Colors.white70),
        floatingLabelStyle: const TextStyle(fontSize: 13, color: AppColors.primaryLight, fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D1F45),
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed, elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryLight, unselectedLabelColor: Colors.white60,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.primaryLight, width: 3)),
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF0D1F45), elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)), side: BorderSide(color: Color(0xFF1E3060), width: 1)),
      ),
      dividerTheme: const DividerThemeData(thickness: 1, color: Color(0xFF1E2E55), space: 1),
    );
  }

  // ── Midnight (Pure black + purple) ──────────────────────
  static ThemeData get midnightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _midnightPrimary,
        primary: _midnightPrimary,
        secondary: _midnightAccent,
        surface: _midnightCard,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: _midnightBg,
      textTheme: _textTheme(Colors.white, Colors.white60),
      appBarTheme: const AppBarTheme(
        elevation: 0, centerTitle: true,
        backgroundColor: _midnightSurface,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _midnightPrimary, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54), elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _midnightAccent, minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: _midnightAccent, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: _midnightCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _midnightAccent.withValues(alpha: 0.25), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _midnightAccent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.danger, width: 1)),
        labelStyle: const TextStyle(fontSize: 14, color: Colors.white60),
        floatingLabelStyle: const TextStyle(fontSize: 13, color: _midnightAccent, fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _midnightSurface,
        selectedItemColor: _midnightAccent,
        unselectedItemColor: Colors.white30,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed, elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _midnightAccent, unselectedLabelColor: Colors.white54,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: _midnightAccent, width: 3)),
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: _midnightCard, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: _midnightAccent.withValues(alpha: 0.2), width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(thickness: 1, color: _midnightAccent.withValues(alpha: 0.15), space: 1),
    );
  }
}
