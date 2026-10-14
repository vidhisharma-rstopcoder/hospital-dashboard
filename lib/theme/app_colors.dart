import 'package:flutter/material.dart';

/// Product palette. Ink and indigo for chrome, separate hues for clinical status.
class AppColors {
  const AppColors._();

  static const night = Color(0xFF0E1730);
  static const deep = Color(0xFF152044);
  static const ink = Color(0xFF12203A);
  static const muted = Color(0xFF5C6B82);
  static const line = Color(0xFFE3E8F2);
  static const canvas = Color(0xFFF4F7FC);
  static const teal = Color(0xFF2F6FED);
  static const tealBright = Color(0xFF67E8F9);
  static const mint = Color(0xFFE8F1FF);
  static const admitted = Color(0xFF2F6FED);
  static const discharged = Color(0xFF12B981);
  static const observation = Color(0xFFF59E0B);
  static const critical = Color(0xFFEF4444);
  static const gold = Color(0xFF7C5CFF);
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
