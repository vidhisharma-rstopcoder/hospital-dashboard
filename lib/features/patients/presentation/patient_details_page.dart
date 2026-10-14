import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/common/format.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/common/widgets/entrance.dart';
import 'package:hospital_dashboard/common/widgets/shimmer_box.dart';
import 'package:hospital_dashboard/common/widgets/state_message.dart';
import 'package:hospital_dashboard/common/widgets/status_chip.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/presentation/patient_providers.dart';
import 'package:hospital_dashboard/features/patients/presentation/widgets/patient_avatar.dart';

class PatientDetailsPage extends ConsumerWidget {
  const PatientDetailsPage({required this.patientId, super.key});

  final int? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = patientId;
    if (id == null) {
      return const StateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Unknown chart',
        message: 'The ID in the URL is not valid.',
      );
    }

    final patient = ref.watch(patientDetailsProvider(id));
    return patient.when(
      loading: () => const _DetailsSkeleton(),
      error: (error, _) => StateMessage(
        icon: Icons.personal_injury_outlined,
        title: 'Chart unavailable',
        message: error is PatientApiException
            ? error.message
            : 'Could not load this patient.',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(patientDetailsProvider(id)),
      ),
      data: (data) => _DetailsBody(patient: data),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final info = _InfoSection(
          title: 'Patient information',
          rows: [
            _Fact('Full name', patient.name),
            _Fact('Patient ID', '${patient.id}'),
            _Fact('Gender', patient.gender),
            _Fact('Date of birth', formatHospitalDate(patient.dateOfBirth)),
            _Fact('Age', '${patient.ageOn(now)} years'),
            _Fact('Blood group', displayText(patient.bloodGroup)),
          ],
        );
        final contact = _InfoSection(
          title: 'Contact details',
          rows: [
            _Fact('Phone', displayText(patient.phone)),
            _Fact('Email', displayText(patient.email)),
            _Fact('Address', displayText(patient.address)),
            _Fact(
              'Emergency contact',
              displayText(patient.emergencyContactName),
            ),
            _Fact(
              'Emergency phone',
              displayText(patient.emergencyContactPhone),
            ),
            _Fact('Insurance', displayText(patient.insuranceProvider)),
          ],
        );
        final admission = _InfoSection(
          title: 'Admission information',
          rows: [
            _Fact('Admission date', formatHospitalDate(patient.admissionDate)),
            _Fact('Ward', displayText(patient.ward)),
            _Fact('Room', displayText(patient.room)),
            _Fact('Attending doctor', displayText(patient.attendingDoctor)),
            _Fact('Diagnosis', displayText(patient.diagnosis)),
            _Fact('Length of stay', patientStayLabel(patient, now)),
          ],
        );
        final status = _StatusPanel(patient: patient);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/patients');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Patients'),
                  ),
                  const SizedBox(height: 8),
                  Entrance(
                    child: _Hero(patient: patient, now: now),
                  ),
                  const SizedBox(height: 16),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: info),
                        const SizedBox(width: 16),
                        Expanded(child: contact),
                      ],
                    )
                  else ...[
                    info,
                    const SizedBox(height: 16),
                    contact,
                  ],
                  const SizedBox(height: 16),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: admission),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: status),
                      ],
                    )
                  else ...[
                    admission,
                    const SizedBox(height: 16),
                    status,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.patient, required this.now});

  final Patient patient;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0D12), Color(0xFF312E81)],
        ),
        boxShadow: AppColors.cardShadow(lifted: true),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PatientAvatar(
            name: patient.name,
            radius: 30,
            heroTag: 'patient-${patient.id}',
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ${patient.id}  ·  ${patientStayLabel(patient, now)}',
                  style: const TextStyle(
                    color: Color(0xFFC5D4E0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(status: patient.status),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_Fact> rows;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final row in rows) _FactLine(fact: row),
        ],
      ),
    );
  }
}

class _Fact {
  const _Fact(this.label, this.value);

  final String label;
  final String value;
}

class _FactLine extends StatelessWidget {
  const _FactLine({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              fact.label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              fact.value,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(patient.status);
    final narrative = switch (patient.status) {
      PatientStatus.admitted => 'Currently admitted.',
      PatientStatus.observation => 'Under observation. Not discharged yet.',
      PatientStatus.critical => 'Critical. Needs close monitoring.',
      PatientStatus.discharged => 'Discharged. Record stays in the list.',
    };
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(status: patient.status),
                const SizedBox(height: 10),
                Text(
                  narrative,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 20, width: 120),
          SizedBox(height: 16),
          ShimmerBox(height: 120, radius: 24),
          SizedBox(height: 16),
          ShimmerBox(height: 180, radius: 22),
        ],
      ),
    );
  }
}
