import 'package:flutter/material.dart';

/// Central colours + theme for Haptic Drive.
/// Palette derived from the Figma mockups: soft sage-green accent,
/// off-white background, rounded "pill" buttons.
class AppColors {
  static const Color sage = Color(0xFF7FB8A6); // primary accent
  static const Color sageDark = Color(0xFF4F8E7C);
  static const Color sageSoft = Color(0xFFD9ECE5); // pill button fill
  static const Color background = Color(0xFFF4F6F5);
  static const Color card = Colors.white;
  static const Color ink = Color(0xFF1F2A26);
  static const Color inkSoft = Color(0xFF6B7A74);
  static const Color line = Color(0xFFE3E8E6);
  static const Color surfaceMuted = Color(0xFFEDEFF1); // inset controls (pulse buttons)
  static const Color warn = Color(0xFFE08A4B);
  static const Color danger = Color(0xFFD45D5D);

  // Accent colours for the results "spatial profile" bars (one per dimension).
  static const Color chartBlue = Color(0xFF3E7CB1);
  static const Color chartGreen = Color(0xFF3FA46B);
  static const Color chartPink = Color(0xFFD94F7A);
  static const Color chartPurple = Color(0xFF7A5BD0);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sage,
      primary: AppColors.sageDark,
      surface: AppColors.card,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sageDark, width: 1.6),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(color: AppColors.ink),
        bodySmall: TextStyle(color: AppColors.inkSoft),
      ),
    );
  }
}
