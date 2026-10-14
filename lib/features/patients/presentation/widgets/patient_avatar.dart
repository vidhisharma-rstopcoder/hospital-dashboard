import 'package:flutter/material.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';

class PatientAvatar extends StatelessWidget {
  const PatientAvatar({
    required this.name,
    this.radius = 20,
    this.heroTag,
    super.key,
  });

  final String name;
  final double radius;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor(name),
      child: Text(
        initials(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.68,
        ),
      ),
    );
    if (heroTag == null) return avatar;
    return Hero(
      tag: heroTag!,
      flightShuttleBuilder: (context, animation, direction, from, to) {
        return to.widget;
      },
      child: Material(type: MaterialType.transparency, child: avatar),
    );
  }
}

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color avatarColor(String name) {
  const palette = [
    Color(0xFF4F46E5),
    Color(0xFF0369A1),
    Color(0xFFB45309),
    Color(0xFF6D28D9),
    Color(0xFFBE123C),
    Color(0xFF0E7490),
  ];
  return palette[(name.hashCode & 0x7fffffff) % palette.length];
}

String patientStayLabel(Patient patient, DateTime now) {
  if (!patient.status.inCare) return 'Discharged from inpatient care';
  final days = DateTime(now.year, now.month, now.day)
      .difference(
        DateTime(
          patient.admissionDate.year,
          patient.admissionDate.month,
          patient.admissionDate.day,
        ),
      )
      .inDays;
  if (days <= 0) return 'Admitted today';
  if (days == 1) return 'Day 1 of admission';
  return 'Day $days of admission';
}
