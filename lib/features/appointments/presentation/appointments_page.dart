import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_dashboard/common/widgets/state_message.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AppointmentsPage extends ConsumerStatefulWidget {
  const AppointmentsPage({super.key});

  @override
  ConsumerState<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends ConsumerState<AppointmentsPage> {
  final _reason = TextEditingController();
  DateTime? _when;
  var _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final auth = ref.read(authControllerProvider);
    final patientId = auth.patientId;
    final doctorId = auth.doctorId;
    if (patientId == null || doctorId == null) {
      _toast('A doctor has to be assigned first.');
      return;
    }
    if (_when == null) {
      _toast('Choose a time.');
      return;
    }
    setState(() => _saving = true);
    try {
      final store = await ref.read(clinicStoreProvider.future);
      await store.requestConsultation(
        auth.actor,
        patientId: patientId,
        doctorId: doctorId,
        scheduledAt: _when!,
        reason: _reason.text,
      );
      if (!mounted) return;
      _reason.clear();
      _toast('Request sent.');
    } catch (error) {
      if (mounted) _toast(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _set(String id, AppointmentStatus status) async {
    try {
      final store = await ref.read(clinicStoreProvider.future);
      await store.setAppointmentStatus(
        ref.read(authControllerProvider).actor,
        id,
        status,
      );
    } catch (error) {
      if (mounted) _toast(error.toString());
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final items = ref.watch(_appointmentListProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const Text('Appointments', style: AppType.title),
        const SizedBox(height: 6),
        const Text(
          'Consultation requests between a patient and their doctor.',
          style: AppType.body,
        ),
        if (auth.role == UserRole.patient) ...[
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request a consultation',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 10, minute: 0),
                    );
                    if (time == null) return;
                    setState(() {
                      _when = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  child: Text(
                    _when == null
                        ? 'Choose date and time'
                        : DateFormat('d MMM, h:mm a').format(_when!),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reason,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _saving ? null : _request,
                  child: Text(_saving ? 'Sending...' : 'Send request'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        items.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => StateMessage(
            icon: Icons.event_busy_rounded,
            title: 'Appointments unavailable',
            message: error.toString(),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const StateMessage(
                icon: Icons.event_available_rounded,
                title: 'No consultations',
                message: 'Requests will show up here.',
              );
            }
            return Column(
              children: [
                for (final item in list) ...[
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient ${item.patientId} · ${item.doctorId}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d MMM yyyy, h:mm a')
                              .format(item.scheduledAt),
                        ),
                        Text(
                          item.reason.isEmpty
                              ? 'No reason given.'
                              : item.reason,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.status.name,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.status == AppointmentStatus.requested &&
                            (auth.role == UserRole.doctor ||
                                auth.role == UserRole.admin))
                          Row(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    _set(item.id, AppointmentStatus.accepted),
                                child: const Text('Accept'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _set(item.id, AppointmentStatus.rejected),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        if (item.status == AppointmentStatus.requested ||
                            item.status == AppointmentStatus.accepted)
                          TextButton(
                            onPressed: () =>
                                _set(item.id, AppointmentStatus.cancelled),
                            child: const Text('Cancel'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

final _appointmentListProvider = FutureProvider.autoDispose<List<Appointment>>((
  ref,
) async {
  final store = await ref.watch(clinicStoreProvider.future);
  final auth = ref.watch(authControllerProvider);
  final subscription = store.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);
  return store.listAppointments(auth.actor);
});
