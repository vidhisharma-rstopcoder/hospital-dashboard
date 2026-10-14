import 'package:flutter/material.dart';

/// Isometric hospital used on the sign-in screen. Drawn, so it stays sharp at any size.
class HospitalScene extends StatefulWidget {
  const HospitalScene({super.key});

  @override
  State<HospitalScene> createState() => _HospitalSceneState();
}

class _HospitalSceneState extends State<HospitalScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      _float.forward();
    });
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_float.value);
        return CustomPaint(
          painter: _HospitalScenePainter(lift: (1 - t) * 16),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _HospitalScenePainter extends CustomPainter {
  const _HospitalScenePainter({required this.lift});

  final double lift;

  static const _glass = Color(0xFF5EC8FF);
  static const _glassDeep = Color(0xFF2F9FE8);
  static const _blue = Color(0xFF2F7BFF);
  static const _leaf = Color(0xFF3DDC6A);
  static const _leafDeep = Color(0xFF22A84A);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB9E4FF), Color(0xFFE7F6FF), Color(0xFFF3FBFF)],
        ).createShader(rect),
    );
    _cloud(canvas, Offset(size.width * 0.16, size.height * 0.14), 42);
    _cloud(canvas, Offset(size.width * 0.82, size.height * 0.1), 54);

    final scale = (size.height / 320).clamp(0.55, 1.35);
    final shift = size.width > size.height * 1.5 ? size.width * 0.06 : 0.0;
    canvas.save();
    canvas.translate(size.width / 2 + shift, size.height * 0.56 + lift);
    canvas.scale(scale);
    _complex(canvas);
    canvas.restore();
  }

  void _cloud(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );
  }

  Offset _p(double x, double y, double z) =>
      Offset((x - y) * 0.92, (x + y) * 0.48 - z);

  void _face(Canvas canvas, List<Offset> points, Color color) {
    canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
  }

  void _box(
    Canvas canvas, {
    required double x,
    required double y,
    required double z,
    required double w,
    required double d,
    required double h,
    Color top = const Color(0xFFF7FBFF),
    Color left = const Color(0xFFE7F0F8),
    Color right = const Color(0xFFD5E3F2),
  }) {
    _face(canvas, [
      _p(x, y, z + h),
      _p(x + w, y, z + h),
      _p(x + w, y + d, z + h),
      _p(x, y + d, z + h),
    ], top);
    _face(canvas, [
      _p(x, y + d, z),
      _p(x + w, y + d, z),
      _p(x + w, y + d, z + h),
      _p(x, y + d, z + h),
    ], left);
    _face(canvas, [
      _p(x + w, y, z),
      _p(x + w, y + d, z),
      _p(x + w, y + d, z + h),
      _p(x + w, y, z + h),
    ], right);
  }

  void _windows(
    Canvas canvas, {
    required double x,
    required double y,
    required double z,
    required double w,
    required double h,
    required bool alongX,
    required int cols,
    required int rows,
  }) {
    const gap = 7.0;
    final span = w;
    final cell = (span - gap * (cols + 1)) / cols;
    final cellH = (h - gap * (rows + 1)) / rows;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final inset = gap + col * (cell + gap);
        final rise = gap + row * (cellH + gap);
        if (alongX) {
          _face(canvas, [
            _p(x + inset, y, z + rise),
            _p(x + inset + cell, y, z + rise),
            _p(x + inset + cell, y, z + rise + cellH),
            _p(x + inset, y, z + rise + cellH),
          ], row.isEven ? _glass : _glassDeep);
        } else {
          _face(canvas, [
            _p(x, y + inset, z + rise),
            _p(x, y + inset + cell, z + rise),
            _p(x, y + inset + cell, z + rise + cellH),
            _p(x, y + inset, z + rise + cellH),
          ], row.isEven ? _glass : _glassDeep);
        }
      }
    }
  }

  void _tree(Canvas canvas, double x, double y, double scale) {
    final trunk = Paint()..color = const Color(0xFFB7793A);
    canvas.drawLine(_p(x, y, 8), _p(x, y, 22), trunk..strokeWidth = 3);
    canvas.drawCircle(
      _p(x, y, 28 * scale),
      14 * scale,
      Paint()..color = _leafDeep,
    );
    canvas.drawCircle(_p(x, y, 40 * scale), 10 * scale, Paint()..color = _leaf);
  }

  void _card(Canvas canvas, Offset center, void Function(Canvas, Offset) icon) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 42, height: 42),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      rect.shift(const Offset(0, 5)),
      Paint()
        ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFD7E9FF),
    );
    icon(canvas, center);
  }

  void _heart(Canvas canvas, Offset c) {
    final path = Path()
      ..moveTo(c.dx, c.dy + 8)
      ..cubicTo(c.dx - 14, c.dy - 2, c.dx - 8, c.dy - 12, c.dx, c.dy - 4)
      ..cubicTo(c.dx + 8, c.dy - 12, c.dx + 14, c.dy - 2, c.dx, c.dy + 8);
    canvas.drawPath(path, Paint()..color = const Color(0xFFEF4444));
    canvas.drawLine(
      c + const Offset(-1, -2),
      c + const Offset(3, 2),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      c + const Offset(3, -2),
      c + const Offset(-1, 2),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _pulse(Canvas canvas, Offset c) {
    final path = Path()
      ..moveTo(c.dx - 14, c.dy + 2)
      ..lineTo(c.dx - 6, c.dy + 2)
      ..lineTo(c.dx - 2, c.dy - 8)
      ..lineTo(c.dx + 3, c.dy + 8)
      ..lineTo(c.dx + 7, c.dy + 2)
      ..lineTo(c.dx + 14, c.dy + 2);
    canvas.drawPath(
      path,
      Paint()
        ..color = _blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _bed(Canvas canvas, Offset c) {
    final paint = Paint()
      ..color = _blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + const Offset(0, 4), width: 22, height: 10),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawLine(c + const Offset(-8, 8), c + const Offset(-8, -6), paint);
    canvas.drawLine(c + const Offset(-8, -6), c + const Offset(2, -6), paint);
  }

  void _scope(Canvas canvas, Offset c) {
    final paint = Paint()
      ..color = _blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c + const Offset(-6, 4), 5, paint);
    canvas.drawCircle(c + const Offset(6, 4), 5, paint);
    canvas.drawArc(
      Rect.fromCenter(center: c + const Offset(0, -2), width: 16, height: 14),
      3.4,
      2.6,
      false,
      paint,
    );
  }

  void _complex(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(10, 70), width: 420, height: 150),
      Paint()..color = const Color(0xFF93C5FD).withValues(alpha: 0.28),
    );

    _box(
      canvas,
      x: -170,
      y: -110,
      z: 0,
      w: 340,
      d: 230,
      h: 18,
      top: const Color(0xFFF4F8FC),
      left: const Color(0xFFE4EDF6),
      right: const Color(0xFFD7E4F1),
    );

    _tree(canvas, -120, -40, 1);
    _tree(canvas, -90, -70, 0.8);
    _tree(canvas, 130, -50, 0.9);

    _box(canvas, x: -30, y: -55, z: 18, w: 150, d: 110, h: 92);
    _windows(
      canvas,
      x: -30,
      y: 55,
      z: 32,
      w: 150,
      h: 62,
      alongX: true,
      cols: 4,
      rows: 2,
    );
    _windows(
      canvas,
      x: 120,
      y: -55,
      z: 32,
      w: 110,
      h: 62,
      alongX: false,
      cols: 3,
      rows: 2,
    );

    _box(
      canvas,
      x: 10,
      y: -25,
      z: 110,
      w: 70,
      d: 56,
      h: 28,
      top: const Color(0xFFF8FBFF),
    );
    final cross = Paint()..color = _blue;
    final crossCenter = _p(45, 3, 142);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: crossCenter, width: 28, height: 10),
        const Radius.circular(2),
      ),
      cross,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: crossCenter, width: 10, height: 28),
        const Radius.circular(2),
      ),
      cross,
    );

    _box(canvas, x: 108, y: -20, z: 18, w: 78, d: 78, h: 64);
    _windows(
      canvas,
      x: 186,
      y: -20,
      z: 30,
      w: 78,
      h: 40,
      alongX: false,
      cols: 2,
      rows: 2,
    );
    final pad = _p(147, 19, 84);
    canvas.drawCircle(pad, 18, Paint()..color = const Color(0xFFE8F4FF));
    canvas.drawCircle(
      pad,
      18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _blue,
    );
    _label(canvas, 'H', pad + const Offset(-4, -6), 12, _blue);

    _box(
      canvas,
      x: -8,
      y: 40,
      z: 48,
      w: 92,
      d: 8,
      h: 16,
      top: _blue,
      left: const Color(0xFF1D4ED8),
      right: const Color(0xFF1D4ED8),
    );
    _label(canvas, 'HOSPITAL', _p(8, 50, 54), 11, Colors.white);

    _tree(canvas, 40, 95, 0.85);
    _tree(canvas, 150, 70, 1.05);
    _tree(canvas, -140, 60, 0.75);
    _tree(canvas, 90, 110, 0.7);

    _ambulance(canvas);

    final iconLift = -lift * 0.35;
    _card(canvas, const Offset(-150, -150) + Offset(0, iconLift), _pulse);
    _card(canvas, const Offset(150, -160) + Offset(0, iconLift), _heart);
    _card(canvas, const Offset(-185, -40) + Offset(0, iconLift), _scope);
    _card(canvas, const Offset(190, -30) + Offset(0, iconLift), _bed);
    _dots(canvas, const Offset(-120, -130), _p(20, -20, 130));
    _dots(canvas, const Offset(130, -140), _p(70, 0, 130));
  }

  void _ambulance(Canvas canvas) {
    _box(
      canvas,
      x: -130,
      y: 70,
      z: 18,
      w: 62,
      d: 28,
      h: 22,
      top: Colors.white,
      left: const Color(0xFFF8FBFF),
      right: const Color(0xFFE8EEF5),
    );
    _face(canvas, [
      _p(-130, 98, 26),
      _p(-80, 98, 26),
      _p(-80, 98, 34),
      _p(-130, 98, 34),
    ], const Color(0xFFEF4444));
    canvas.drawCircle(
      _p(-112, 96, 18),
      5,
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawCircle(
      _p(-86, 90, 18),
      5,
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawCircle(
      _p(-118, 86, 36),
      3.5,
      Paint()..color = const Color(0xFF60A5FA),
    );
    canvas.drawCircle(
      _p(-108, 84, 36),
      3.5,
      Paint()..color = const Color(0xFFF87171),
    );
  }

  void _label(Canvas canvas, String text, Offset at, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  void _dots(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()..color = const Color(0xFF93C5FD);
    for (var i = 0; i <= 4; i++) {
      final t = i / 4;
      canvas.drawCircle(Offset.lerp(from, to, t)!, i == 4 ? 2.4 : 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HospitalScenePainter oldDelegate) {
    return oldDelegate.lift != lift;
  }
}
