import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_dashboard/features/dashboard/domain/dashboard_stats.dart';
import 'package:hospital_dashboard/features/patients/data/patient_providers.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final patients = await ref.watch(patientRepositoryProvider).fetchAll();
  return DashboardStats.fromPatients(patients);
});
