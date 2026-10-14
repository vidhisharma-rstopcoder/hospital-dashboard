import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/common/widgets/state_message.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';

class DoctorProfilePage extends ConsumerWidget {
  const DoctorProfilePage({required this.doctorId, super.key});

  final String? doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = doctorId;
    if (id == null || id.isEmpty) {
      return const StateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Unknown doctor',
        message: 'The ID in the URL is not valid.',
      );
    }
    final profile = ref.watch(_profileProvider(id));
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => StateMessage(
        icon: Icons.medical_services_outlined,
        title: 'Profile unavailable',
        message: error.toString(),
      ),
      data: (data) => _Body(doctor: data.doctor, patients: data.patients),
    );
  }
}

class _Profile {
  const _Profile(this.doctor, this.patients);
  final Doctor doctor;
  final List<Patient> patients;
}

class _Body extends ConsumerWidget {
  const _Body({required this.doctor, required this.patients});

  final Doctor doctor;
  final List<Patient> patients;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final canEdit = auth.role == UserRole.admin || auth.doctorId == doctor.id;
    ImageProvider? image;
    if (doctor.photoDataUrl.contains(',')) {
      try {
        image = MemoryImage(base64Decode(doctor.photoDataUrl.split(',').last));
      } catch (_) {
        image = null;
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        TextButton.icon(
          onPressed: () => context.go('/doctors'),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Doctors'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.mint,
              backgroundImage: image,
              child: image == null
                  ? const Icon(Icons.person_rounded, color: AppColors.teal)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.name, style: AppType.title),
                  Text(
                    '${doctor.specialization} · ${doctor.qualification}',
                    style: AppType.body,
                  ),
                ],
              ),
            ),
            if (canEdit)
              OutlinedButton(
                onPressed: () => context.go('/doctors/${doctor.id}/edit'),
                child: const Text('Edit'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${doctor.yearsExperience} years at ${doctor.hospital}'),
              const SizedBox(height: 6),
              Text('Fee ₹${doctor.consultationFee}'),
              const SizedBox(height: 6),
              Text(
                '${doctor.availableDays.join(', ')} · ${doctor.timeSlots.join(', ')}',
              ),
              const SizedBox(height: 6),
              Text(doctor.phone),
              Text(doctor.email),
              if (doctor.bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(doctor.bio),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Assigned patients', style: AppType.section),
        const SizedBox(height: 8),
        if (patients.isEmpty)
          const Text('No active patients.', style: AppType.body)
        else
          for (final patient in patients)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(patient.name),
              subtitle: Text('ID ${patient.id}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/patients/${patient.id}'),
            ),
      ],
    );
  }
}

final _profileProvider = FutureProvider.autoDispose.family<_Profile, String>((
  ref,
  id,
) async {
  final store = await ref.watch(clinicStoreProvider.future);
  final actor = ref.watch(authControllerProvider).actor;
  final doctor = await store.getDoctor(actor, id);
  final patients = actor.isAdmin || actor.doctorId == id
      ? await store.patientsForDoctor(actor, id)
      : const <Patient>[];
  return _Profile(doctor, patients);
});
