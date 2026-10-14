import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/common/format.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:hospital_dashboard/common/widgets/entrance.dart';
import 'package:hospital_dashboard/common/widgets/shimmer_box.dart';
import 'package:hospital_dashboard/common/widgets/state_message.dart';
import 'package:hospital_dashboard/common/widgets/status_chip.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/features/clinic/presentation/clinic_providers.dart';
import 'package:hospital_dashboard/features/dashboard/domain/dashboard_stats.dart';
import 'package:hospital_dashboard/features/dashboard/presentation/dashboard_providers.dart';
import 'package:hospital_dashboard/features/dashboard/presentation/widgets/admission_charts.dart';
import 'package:hospital_dashboard/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/presentation/widgets/patient_avatar.dart';
import 'package:intl/intl.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return stats.when(
      loading: () => const _DashboardSkeleton(),
      error: (error, _) => StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Dashboard unavailable',
        message: error is PatientApiException
            ? error.message
            : 'The dashboard could not be loaded.',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(dashboardStatsProvider),
      ),
      data: (data) => _DashboardBody(stats: data),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = (constraints.maxWidth - 48).clamp(0.0, 1200.0);
        final columns = contentWidth >= 1100
            ? 4
            : contentWidth >= 680
            ? 2
            : 1;
        const gap = 16.0;
        final cardWidth = (contentWidth - (gap * (columns - 1))) / columns;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Entrance(child: _Header(now: now)),
                  const SizedBox(height: 16),
                  const _ClinicStrip(),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      _card(
                        cardWidth,
                        0,
                        StatCard(
                          label: 'Total patients',
                          value: stats.total,
                          caption: 'All records on this desk',
                          icon: Icons.groups_rounded,
                          accent: AppColors.teal,
                          onTap: () => context.go('/patients'),
                        ),
                      ),
                      _card(
                        cardWidth,
                        1,
                        StatCard(
                          label: 'Currently admitted',
                          value: stats.byStatus[PatientStatus.admitted] ?? 0,
                          caption: stats.shareLabel(PatientStatus.admitted),
                          icon: Icons.bed_rounded,
                          accent: AppColors.admitted,
                          onTap: () => context.go('/patients?status=Admitted'),
                        ),
                      ),
                      _card(
                        cardWidth,
                        2,
                        StatCard(
                          label: 'Discharged patients',
                          value: stats.discharged,
                          caption: stats.shareLabel(PatientStatus.discharged),
                          icon: Icons.exit_to_app_rounded,
                          accent: AppColors.discharged,
                          onTap: () =>
                              context.go('/patients?status=Discharged'),
                        ),
                      ),
                      _card(
                        cardWidth,
                        3,
                        StatCard(
                          label: "Today's admissions",
                          value: stats.todaysAdmissions,
                          caption: stats.todayChange,
                          icon: Icons.today_rounded,
                          accent: AppColors.gold,
                          onTap: () => context.go('/patients'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Entrance(
                    delay: const Duration(milliseconds: 180),
                    child: AdmissionCharts(stats: stats),
                  ),
                  const SizedBox(height: 16),
                  Entrance(
                    delay: const Duration(milliseconds: 240),
                    child: _RecentAdmissions(patients: stats.recent),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _card(double width, int index, Widget child) {
    return SizedBox(
      width: width.clamp(0, 1200),
      child: Entrance(
        delay: Duration(milliseconds: 50 * index),
        child: child,
      ),
    );
  }
}

class _ClinicStrip extends ConsumerWidget {
  const _ClinicStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(clinicSummaryProvider);
    final role = ref.watch(authControllerProvider).role;
    return summary.maybeWhen(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill('Patients', data.totalPatients),
              _Pill('Doctors', data.totalDoctors),
              _Pill('Active links', data.activeRelationships),
              _Pill('Upcoming', data.upcomingAppointments),
              _Pill('Requests', data.pendingRequests),
              _Pill('Unread', data.unreadMessages),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (role == UserRole.admin)
                _Action('Add patient', () => context.go('/patients/new')),
              if (role == UserRole.admin)
                _Action('Add doctor', () => context.go('/doctors/new')),
              _Action('Appointments', () => context.go('/appointments')),
              _Action('Messages', () => context.go('/messages')),
            ],
          ),
        ],
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rounds', style: AppType.title),
              const SizedBox(height: 8),
              Text(
                'City Hospital  ·  ${DateFormat('EEEE, d MMMM').format(now)}',
                style: AppType.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentAdmissions extends StatelessWidget {
  const _RecentAdmissions({required this.patients});

  final List<Patient> patients;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent admissions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Latest admissions',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/patients'),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final patient in patients) _RecentRow(patient: patient),
        ],
      ),
    );
  }
}

class _RecentRow extends StatefulWidget {
  const _RecentRow({required this.patient});

  final Patient patient;

  @override
  State<_RecentRow> createState() => _RecentRowState();
}

class _RecentRowState extends State<_RecentRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/patients/${patient.id}'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _hover ? AppColors.mint : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${patient.ward}  ·  ${formatHospitalDate(patient.admissionDate)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(status: patient.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 28, width: 280),
          SizedBox(height: 10),
          ShimmerBox(height: 16, width: 220),
          SizedBox(height: 22),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ShimmerBox(height: 150, width: 240, radius: 22),
              ShimmerBox(height: 150, width: 240, radius: 22),
              ShimmerBox(height: 150, width: 240, radius: 22),
              ShimmerBox(height: 150, width: 240, radius: 22),
            ],
          ),
          SizedBox(height: 16),
          ShimmerBox(height: 280, radius: 22),
        ],
      ),
    );
  }
}
