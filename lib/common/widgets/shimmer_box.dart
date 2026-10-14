import 'package:flutter/material.dart';

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    this.height = 16,
    this.width = double.infinity,
    this.radius = 10,
    super.key,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _box(const Color(0xFFE7EEF5));
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final slide = Curves.easeInOut.transform(_controller.value) * 2 - 1;
            return LinearGradient(
              begin: Alignment(slide - 0.8, 0),
              end: Alignment(slide + 0.8, 0),
              colors: const [
                Color(0xFFE6E8EE),
                Color(0xFFF7F8FA),
                Color(0xFFE6E8EE),
              ],
            ).createShader(rect);
          },
          child: _box(const Color(0xFFE7EEF5)),
        );
      },
    );
  }

  Widget _box(Color color) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
  }
}
