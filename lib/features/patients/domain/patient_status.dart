import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';

enum PatientStatus {
  admitted('Admitted'),
  discharged('Discharged'),
  observation('Observation'),
  critical('Critical');

  const PatientStatus(this.label);

  final String label;

  String get displayLabel =>
      this == PatientStatus.observation ? 'Under Observation' : label;

  bool get inCare => this != PatientStatus.discharged;

  static PatientStatus parse(String raw) {
    final parsed = tryParse(raw);
    if (parsed == null) {
      throw PatientApiException('Unknown patient status "$raw".');
    }
    return parsed;
  }

  static PatientStatus? tryParse(String? raw) {
    if (raw == null) return null;
    final value = raw.trim().toLowerCase();
    if (value.isEmpty || value == 'all') return null;
    for (final status in PatientStatus.values) {
      if (status.label.toLowerCase() == value ||
          status.displayLabel.toLowerCase() == value ||
          status.name == value) {
        return status;
      }
    }
    return null;
  }
}
