import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/common/widgets/state_message.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';

class DoctorsPage extends ConsumerStatefulWidget {
  const DoctorsPage({super.key});

  @override
  ConsumerState<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends ConsumerState<DoctorsPage> {
  final _search = TextEditingController();
  String _specialization = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(
      _doctorListProvider((
        search: _search.text,
        specialization: _specialization,
      )),
    );
    final catalog = ref.watch(
      _doctorListProvider((search: '', specialization: 'All')),
    );
    final admin = ref.watch(authControllerProvider).role == UserRole.admin;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doctors', style: AppType.title),
                    SizedBox(height: 6),
                    Text('Name or specialization.', style: AppType.body),
                  ],
                ),
              ),
              if (admin)
                FilledButton.icon(
                  onPressed: () => context.go('/doctors/new'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add doctor'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search doctors',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          doctors.when(
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Expanded(
              child: StateMessage(
                icon: Icons.medical_services_outlined,
                title: 'Doctors unavailable',
                message: error.toString(),
              ),
            ),
            data: (items) {
              final specs = {
                'All',
                ...catalog.maybeWhen(
                  data: (all) => all.map((doctor) => doctor.specialization),
                  orElse: () => items.map((doctor) => doctor.specialization),
                ),
              };
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final spec in specs)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(spec),
                                selected: _specialization == spec,
                                onSelected: (_) =>
                                    setState(() => _specialization = spec),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: items.isEmpty
                          ? const StateMessage(
                              icon: Icons.search_off_rounded,
                              title: 'No doctors',
                              message: 'No doctor matches that search.',
                            )
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) =>
                                  _DoctorCard(doctor: items[index]),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (doctor.photoDataUrl.contains(',')) {
      try {
        image = MemoryImage(base64Decode(doctor.photoDataUrl.split(',').last));
      } catch (_) {
        image = null;
      }
    }
    return SurfaceCard(
      onTap: () => context.go('/doctors/${doctor.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.mint,
            backgroundImage: image,
            child: image == null
                ? Text(
                    doctor.name
                        .split(' ')
                        .map((part) => part.isEmpty ? '' : part[0])
                        .take(2)
                        .join(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${doctor.specialization} · ${doctor.yearsExperience} years',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${doctor.availableDays.join(', ')} · ${doctor.timeSlots.join(', ')}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

final _doctorListProvider = FutureProvider.autoDispose
    .family<List<Doctor>, ({String search, String specialization})>((
      ref,
      query,
    ) async {
      final store = await ref.watch(clinicStoreProvider.future);
      final auth = ref.watch(authControllerProvider);
      final subscription = store.changes.listen((_) => ref.invalidateSelf());
      ref.onDispose(subscription.cancel);
      return store.listDoctors(
        auth.actor,
        search: query.search,
        specialization: query.specialization,
      );
    });
