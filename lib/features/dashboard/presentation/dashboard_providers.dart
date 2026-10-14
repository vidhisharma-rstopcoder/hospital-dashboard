import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_dashboard/config/app_config.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/dashboard/domain/dashboard_stats.dart';
import 'package:hospital_dashboard/features/patients/data/patient_providers.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  if (AppConfig.useMockApi && !AppConfig.simulateApiError) {
    final store = await ref.watch(clinicStoreProvider.future);
    final auth = ref.watch(authControllerProvider);
    final subscription = store.changes.listen((_) => ref.invalidateSelf());
    ref.onDispose(subscription.cancel);
    final patients = await store.visiblePatients(auth.actor);
    return DashboardStats.fromPatients(patients);
  }
  final patients = await ref.watch(patientRepositoryProvider).fetchAll();
  return DashboardStats.fromPatients(patients);
});
