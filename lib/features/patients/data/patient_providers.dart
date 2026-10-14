import 'package:hospital_dashboard/config/app_config.dart';
import 'package:hospital_dashboard/features/patients/data/mock_patient_repository.dart';
import 'package:hospital_dashboard/features/patients/data/patient_repository.dart';
import 'package:hospital_dashboard/features/patients/data/remote_patient_repository.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  if (AppConfig.useMockApi) {
    return MockPatientRepository(simulateError: AppConfig.simulateApiError);
  }
  final client = http.Client();
  ref.onDispose(client.close);
  return RemotePatientRepository(baseUrl: AppConfig.apiBaseUrl, client: client);
});
