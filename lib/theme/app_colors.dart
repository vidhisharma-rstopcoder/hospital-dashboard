import 'package:flutter/material.dart';

/// Product palette. Ink and indigo for chrome, separate hues for clinical status.
class AppColors {
  const AppColors._();

  static const night = Color(0xFF0B0D12);
  static const deep = Color(0xFF16181F);
  static const ink = Color(0xFF101114);
  static const muted = Color(0xFF5C6570);
  static const line = Color(0xFFE6E7EB);
  static const canvas = Color(0xFFF4F5F7);
  static const teal = Color(0xFF4F46E5);
  static const tealBright = Color(0xFF818CF8);
  static const mint = Color(0xFFEEF0FF);
  static const admitted = Color(0xFF1D4ED8);
  static const discharged = Color(0xFF047857);
  static const observation = Color(0xFFB45309);
  static const critical = Color(0xFFBE123C);
  static const gold = Color(0xFF6D28D9);
  static const white = Color(0xFFFFFFFF);

  static const shadow = Color(0xFF101114);

  static List<BoxShadow> cardShadow({bool lifted = false}) {
    return [
      BoxShadow(
        color: shadow.withValues(alpha: lifted ? 0.08 : 0.04),
        blurRadius: lifted ? 28 : 16,
        offset: Offset(0, lifted ? 14 : 8),
      ),
      BoxShadow(
        color: shadow.withValues(alpha: 0.03),
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
    ];
  }
}
