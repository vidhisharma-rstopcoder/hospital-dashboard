import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_dashboard/config/app_config.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/patients/data/patient_providers.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_page_result.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';

class PatientQuery {
  const PatientQuery({
    this.search = '',
    this.status,
    this.page = 1,
    this.pageSize = 10,
  });

  final String search;
  final PatientStatus? status;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is PatientQuery &&
        other.search == search &&
        other.status == status &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(search, status, page, pageSize);
}

PatientQuery queryFromUri(Uri uri) {
  final page = int.tryParse(uri.queryParameters['page'] ?? '') ?? 1;
  return PatientQuery(
    search: uri.queryParameters['q'] ?? '',
    status: PatientStatus.tryParse(uri.queryParameters['status']),
    page: page < 1 ? 1 : page,
  );
}

bool get _useClinicRecords =>
    AppConfig.useMockApi && !AppConfig.simulateApiError;

final patientListProvider = FutureProvider.autoDispose
    .family<PatientPageResult, PatientQuery>((ref, query) async {
      if (!_useClinicRecords) {
        return ref
            .watch(patientRepositoryProvider)
            .fetchPatients(
              page: query.page,
              pageSize: query.pageSize,
              search: query.search,
              status: query.status,
            );
      }
      final store = await ref.watch(clinicStoreProvider.future);
      final auth = ref.watch(authControllerProvider);
      final subscription = store.changes.listen((_) => ref.invalidateSelf());
      ref.onDispose(subscription.cancel);
      if (!auth.authenticated) {
        throw PatientApiException('Sign in to view patients.');
      }
      return store.pagePatients(
        auth.actor,
        page: query.page,
        pageSize: query.pageSize,
        search: query.search,
        status: query.status,
      );
    });

final patientDetailsProvider = FutureProvider.autoDispose.family<Patient, int>((
  ref,
  id,
) async {
  if (!_useClinicRecords) {
    return ref.watch(patientRepositoryProvider).fetchPatient(id);
  }
  final store = await ref.watch(clinicStoreProvider.future);
  final auth = ref.watch(authControllerProvider);
  final subscription = store.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);
  if (!auth.authenticated) {
    throw PatientApiException('Sign in to view patients.');
  }
  return store.getPatient(auth.actor, id);
});
