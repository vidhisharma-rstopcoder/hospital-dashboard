import 'package:flutter/material.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';

Color statusColor(PatientStatus status) {
  return switch (status) {
    PatientStatus.admitted => AppColors.admitted,
    PatientStatus.discharged => AppColors.discharged,
    PatientStatus.observation => AppColors.observation,
    PatientStatus.critical => AppColors.critical,
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final PatientStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontFamily: appFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
