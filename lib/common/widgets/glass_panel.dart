import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 20,
    this.dark = false,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(this.radius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: radius,
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.9),
            ),
            boxShadow: dark ? null : AppColors.cardShadow(),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
