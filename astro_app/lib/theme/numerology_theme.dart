import 'package:flutter/material.dart';

/// Central theme helper for all Numerology modules in Astrotalk.
/// Ensures consistent cosmic dark mode styling across every numerology page.
class NumerologyTheme {
  // Deep space dark mode palette
  static const Color darkScaffoldBg = Color(0xFF080D1A);
  static const Color darkCardBg = Color(0xFF131D36);
  static const Color darkCardSurface = Color(0xFF1A2644);
  static const Color darkBorder = Color(0xFF1E2E56);
  static const Color darkInputBg = Color(0xFF0B1120);
  static const Color darkButtonBg = Color(0xFF1E293B);

  // Backgrounds
  static Color scaffoldBg(bool isDark, [Color? lightBg]) =>
      isDark ? darkScaffoldBg : (lightBg ?? const Color(0xFFF8FAFD));

  static Color appBarBg(bool isDark, [Color? lightBg]) =>
      isDark ? darkScaffoldBg : (lightBg ?? Colors.white);

  static Color cardBg(bool isDark, [Color? lightBg]) =>
      isDark ? darkCardBg : (lightBg ?? Colors.white);

  static Color cardBorder(bool isDark, [Color? accentColor, Color? lightBorder]) {
    if (isDark) {
      return accentColor != null
          ? accentColor.withValues(alpha: 0.35)
          : darkBorder;
    }
    return lightBorder ?? (accentColor != null ? accentColor.withValues(alpha: 0.25) : const Color(0xFFE2E8F0));
  }

  // Texts
  static Color textPrimary(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF0F172A);

  static Color textSecondary(bool isDark) =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static Color textMuted(bool isDark) =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // Form Inputs
  static Color inputBg(bool isDark, [Color? lightBg]) =>
      isDark ? darkInputBg : (lightBg ?? const Color(0xFFF8FAFD));

  static Color inputBorder(bool isDark) =>
      isDark ? darkBorder : const Color(0xFFE2E8F0);

  static Color inputText(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF1E293B);

  // Circular Action Buttons (back, settings, etc.)
  static Color circleBtnBg(bool isDark) =>
      isDark ? darkCardBg : Colors.white;

  static Color circleBtnBorder(bool isDark, [Color? accent]) =>
      isDark ? (accent != null ? accent.withValues(alpha: 0.3) : darkBorder) : const Color(0xFFE2E8F0);

  static Color circleBtnIcon(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF1E293B);

  // Badges & Chips
  static Color badgeBg(bool isDark, Color lightBg) =>
      isDark ? darkButtonBg : lightBg;

  static Color badgeText(bool isDark, Color lightText) {
    if (isDark) {
      return Colors.white;
    }
    return lightText;
  }

  // Modals & Bottom Sheets
  static Color sheetBg(bool isDark) =>
      isDark ? darkCardBg : Colors.white;

  static Color dropdownBg(bool isDark) =>
      isDark ? darkCardBg : Colors.white;

  static Color divider(bool isDark) =>
      isDark ? darkBorder : const Color(0xFFE2E8F0);

  // Glass card decoration helper
  static BoxDecoration cardDecoration({
    required bool isDark,
    Color? accentColor,
    Color? lightBg,
    Color? lightBorder,
    double borderRadius = 20,
    double borderWidth = 1.2,
  }) {
    final bg = cardBg(isDark, lightBg);
    final border = cardBorder(isDark, accentColor, lightBorder);

    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: border, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: (accentColor ?? (isDark ? Colors.black : Colors.black12))
              .withValues(alpha: isDark ? 0.22 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
