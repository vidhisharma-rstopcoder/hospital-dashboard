import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_page_result.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';

abstract class PatientRepository {
  Future<PatientPageResult> fetchPatients({
    required int page,
    required int pageSize,
    String search = '',
    PatientStatus? status,
  });

  Future<Patient> fetchPatient(int id);

  Future<List<Patient>> fetchAll();
}
