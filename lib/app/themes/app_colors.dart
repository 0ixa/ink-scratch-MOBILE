import 'package:flutter/material.dart';

/// InkScratch Design System — mirrors the CSS custom properties in globals.css
class AppColors {
  AppColors._();

  // ── Brand tokens (never change) ─────────────────────────────────────────
  static const Color orange = Color(0xFFFF6B35);
  static const Color red = Color(0xFFE63946);

  static const Color orangeDim = Color(0x26FF6B35); // rgba(255,107,53,0.15)
  static const Color orangeGlow = Color(0x40FF6B35); // rgba(255,107,53,0.25)

  // ── Dark theme (default) ────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color bg1Dark = Color(0xFF111118);
  static const Color bg2Dark = Color(0xFF16161F);
  static const Color bgCardDark = Color(0xFF1A1A24);
  static const Color bgCardHoverDark = Color(0xFF1F1F2C);
  static const Color bgInputDark = Color(0xFF13131A);
  static const Color bgInputFocusDark = Color(0xFF16161F);

  static const Color borderDark = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color borderCardDark = Color(
    0x0FFFFFFF,
  ); // rgba(255,255,255,0.06)

  static const Color textPrimaryDark = Color(0xFFF0F0F5);
  static const Color textSecondaryDark = Color(0x8CF0F0F5); // 55%
  static const Color textMutedDark = Color(0x4DF0F0F5); // 30%

  // ── Light theme ─────────────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color bg1Light = Color(0xFFF4F4F6);
  static const Color bg2Light = Color(0xFFEDEDF0);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgCardHoverLight = Color(0xFFF8F8FB);
  static const Color bgInputLight = Color(0xFFFFFFFF);
  static const Color bgInputFocusLight = Color(0xFFFFFBF9);

  static const Color borderLight = Color(0x1A000000); // rgba(0,0,0,0.10)
  static const Color borderCardLight = Color(0x14000000); // rgba(0,0,0,0.08)

  static const Color textPrimaryLight = Color(0xFF111118);
  static const Color textSecondaryLight = Color(0xFF5C5C72);
  static const Color textMutedLight = Color(0xFF9898B0);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, red],
  );

  static const LinearGradient brandGradientReverse = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, orange],
  );

  // Right-panel background (auth layout)
  static const LinearGradient authPanelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF0F3460)],
  );

  // ── Shadows ─────────────────────────────────────────────────────────────
  static const Color shadowOrange = Color(0x4DFF6B35); // rgba(255,107,53,0.30)

  // Error / success (alert colours)
  static const Color alertErrorBg = Color(0x1AE63946);
  static const Color alertErrorBorder = Color(0x4DE63946);
  static const Color alertErrorText = Color(0xFFF87171);

  static const Color alertSuccessBg = Color(0x1A22C55E);
  static const Color alertSuccessBorder = Color(0x4D22C55E);
  static const Color alertSuccessText = Color(0xFF4ADE80);
}
