import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppColorPalette {
  midnightCosmic,  // Deep navy, purple, cyan glow
  sacredSaffron,   // Saffron, golden yellow, warm amber
  royalIndigo,     // Royal blue, indigo, silver
  emeraldDivine,   // Emerald green, jade, gold
}

class AppTheme {
  // Midnight Cosmic
  static const Color cosmicNavy = Color(0xFF0B1120);
  static const Color cosmicSurface = Color(0xFF131D36);
  static const Color cosmicBorder = Color(0xFF1E2E56);
  static const Color cosmicAccent = Color(0xFF6366F1);
  static const Color cosmicCyan = Color(0xFF06B6D4);
  static const Color celestialGold = Color(0xFFFFD54F);

  // Sacred Saffron
  static const Color saffronPrimary = Color(0xFFE65100);
  static const Color saffronWarm = Color(0xFFFF9900);
  static const Color saffronGold = Color(0xFFFFB300);
  static const Color saffronDarkBg = Color(0xFF180E05);
  static const Color saffronCard = Color(0xFF26180B);
  static const Color saffronBorder = Color(0xFF5A320C);

  // Royal Indigo
  static const Color royalBlue = Color(0xFF1E40AF);
  static const Color royalIndigo = Color(0xFF4338CA);
  static const Color royalLightBg = Color(0xFFF8FAFC);
  static const Color royalCard = Color(0xFF141C33);
  static const Color royalBorder = Color(0xFF233054);

  // Emerald Divine
  static const Color emeraldPrimary = Color(0xFF047857);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color emeraldDarkBg = Color(0xFF061A14);
  static const Color emeraldCard = Color(0xFF0D2D23);
  static const Color emeraldBorder = Color(0xFF164E3F);

  static LinearGradient getHeaderGradient(AppColorPalette palette, bool isDark) {
    switch (palette) {
      case AppColorPalette.sacredSaffron:
        return const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFC2410C), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppColorPalette.emeraldDivine:
        return const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppColorPalette.royalIndigo:
        return const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppColorPalette.midnightCosmic:
        return const LinearGradient(
          colors: [Color(0xFF0B1120), Color(0xFF131D36), Color(0xFF0A0F1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  static BoxDecoration getGlassCardDecoration({
    required bool isDark,
    Color? accentColor,
    double borderRadius = 20,
  }) {
    final accent = accentColor ?? const Color(0xFF6366F1);
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? accent.withValues(alpha: 0.28)
            : const Color(0xFFCBD5E1).withValues(alpha: 0.8),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration getTempleGoldCardDecoration({
    required bool isDark,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      gradient: isDark
          ? const LinearGradient(
              colors: [Color(0xFF2B1805), Color(0xFF1C0F03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [Color(0xFFFFFBEB), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.45 : 0.35),
        width: 1.3,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static ThemeData getTheme({
    required bool isDark,
    AppColorPalette palette = AppColorPalette.midnightCosmic,
  }) {
    final baseText = isDark
        ? GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.outfitTextTheme(ThemeData.light().textTheme);

    Color bg;
    Color surface;
    Color primary;
    Color border;

    if (isDark) {
      switch (palette) {
        case AppColorPalette.sacredSaffron:
          bg = saffronDarkBg;
          surface = saffronCard;
          primary = saffronWarm;
          border = saffronBorder;
          break;
        case AppColorPalette.emeraldDivine:
          bg = emeraldDarkBg;
          surface = emeraldCard;
          primary = emeraldAccent;
          border = emeraldBorder;
          break;
        case AppColorPalette.royalIndigo:
          bg = const Color(0xFF0A0F1D);
          surface = royalCard;
          primary = const Color(0xFF60A5FA);
          border = royalBorder;
          break;
        case AppColorPalette.midnightCosmic:
          bg = cosmicNavy;
          surface = cosmicSurface;
          primary = cosmicAccent;
          border = cosmicBorder;
          break;
      }
    } else {
      bg = const Color(0xFFF8FAFC);
      surface = Colors.white;
      border = const Color(0xFFE2E8F0);
      switch (palette) {
        case AppColorPalette.sacredSaffron:
          primary = saffronPrimary;
          break;
        case AppColorPalette.emeraldDivine:
          primary = emeraldPrimary;
          break;
        case AppColorPalette.royalIndigo:
          primary = royalBlue;
          break;
        case AppColorPalette.midnightCosmic:
          primary = royalIndigo;
          break;
      }
    }

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primary,
              secondary: celestialGold,
              surface: surface,
              onSurface: Colors.white,
            )
          : ColorScheme.light(
              primary: primary,
              secondary: saffronWarm,
              surface: surface,
              onSurface: const Color(0xFF0F172A),
            ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 14,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 12,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
      ),
    );
  }
}
