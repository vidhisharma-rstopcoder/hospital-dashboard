import 'package:flutter/material.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';

class SurfaceCard extends StatefulWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.white,
    this.onTap,
    this.radius = 16,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  final double radius;

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final motion = !MediaQuery.disableAnimationsOf(context);
    final lifted = _hover && interactive && motion;
    final radius = BorderRadius.circular(widget.radius);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, lifted ? -4 : 0, 0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: radius,
        border: Border.all(
          color: lifted
              ? AppColors.teal.withValues(alpha: 0.35)
              : AppColors.line,
        ),
        boxShadow: AppColors.cardShadow(lifted: lifted),
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    if (!interactive) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        child: GestureDetector(onTap: widget.onTap, child: card),
      ),
    );
  }
}
