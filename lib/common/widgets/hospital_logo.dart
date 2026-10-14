import 'package:flutter/material.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';

class HospitalLogo extends StatelessWidget {
  const HospitalLogo({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cross = size * 0.4;
    final thickness = size * 0.11;
    return Semantics(
      label: 'Rounds',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), AppColors.teal],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.28),
              blurRadius: size * 0.35,
              offset: Offset(0, size * 0.12),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: cross,
            height: cross,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: thickness,
                  height: cross,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Container(
                  width: cross,
                  height: thickness,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
