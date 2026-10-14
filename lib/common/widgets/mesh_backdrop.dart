import 'package:flutter/material.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';

/// Static gradient field. Painted once and held behind a [RepaintBoundary].
class MeshBackdrop extends StatelessWidget {
  const MeshBackdrop({this.dark = false, super.key});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _MeshPainter(dark: dark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  const _MeshPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..color = dark ? AppColors.night : AppColors.canvas,
    );

    void orb(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    if (dark) {
      orb(
        Offset(size.width * 0.15, size.height * 0.2),
        size.shortestSide * 0.55,
        const Color(0xFF4F46E5).withValues(alpha: 0.45),
      );
      orb(
        Offset(size.width * 0.85, size.height * 0.75),
        size.shortestSide * 0.5,
        const Color(0xFF0EA5E9).withValues(alpha: 0.22),
      );
      orb(
        Offset(size.width * 0.6, size.height * 0.15),
        size.shortestSide * 0.28,
        Colors.white.withValues(alpha: 0.08),
      );
      return;
    }

    orb(
      Offset(size.width * 0.9, -20),
      size.shortestSide * 0.45,
      const Color(0xFF4F46E5).withValues(alpha: 0.09),
    );
    orb(
      Offset(-30, size.height * 0.85),
      size.shortestSide * 0.4,
      const Color(0xFF38BDF8).withValues(alpha: 0.07),
    );
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) {
    return oldDelegate.dark != dark;
  }
}
