import 'package:flutter/material.dart';
import 'package:hospital_dashboard/common/format.dart';
import 'package:hospital_dashboard/common/widgets/entrance.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/common/widgets/status_chip.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/presentation/widgets/patient_avatar.dart';

class PatientCards extends StatelessWidget {
  const PatientCards({required this.patients, required this.onOpen, super.key});

  final List<Patient> patients;
  final ValueChanged<Patient> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: patients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Entrance(
          delay: Duration(milliseconds: 40 * index),
          offset: 10,
          child: SurfaceCard(
            padding: const EdgeInsets.all(16),
            onTap: () => onOpen(patient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PatientAvatar(
                      name: patient.name,
                      heroTag: 'patient-${patient.id}',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'ID ${patient.id}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: patient.status),
                  ],
                ),
                const SizedBox(height: 14),
                _Line(label: 'Gender', value: patient.gender),
                _Line(
                  label: 'Date of birth',
                  value: formatHospitalDate(patient.dateOfBirth),
                ),
                _Line(
                  label: 'Admission date',
                  value: formatHospitalDate(patient.admissionDate),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => onOpen(patient),
                    child: const Text('View details'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
