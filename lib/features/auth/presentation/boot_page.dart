import 'package:flutter/material.dart';
import 'package:hospital_dashboard/common/widgets/hospital_logo.dart';
import 'package:hospital_dashboard/common/widgets/mesh_backdrop.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';

class BootPage extends StatelessWidget {
  const BootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MeshBackdrop(dark: true),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HospitalLogo(size: 52),
                SizedBox(height: 18),
                Text(
                  'Rounds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Checking your session',
                  style: TextStyle(
                    color: Color(0xFFC7CDD8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
