import 'package:hospital_dashboard/common/format.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';
import 'package:intl/intl.dart';

class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.inCare,
    required this.discharged,
    required this.todaysAdmissions,
    required this.byStatus,
    required this.weekLabels,
    required this.weekCounts,
    required this.recent,
  });

  final int total;
  final int inCare;
  final int discharged;
  final int todaysAdmissions;
  final Map<PatientStatus, int> byStatus;
  final List<String> weekLabels;
  final List<int> weekCounts;
  final List<Patient> recent;

  String get busiestDay {
    if (weekCounts.isEmpty || weekCounts.every((count) => count == 0)) {
      return 'No admissions this week';
    }
    var index = 0;
    for (var i = 1; i < weekCounts.length; i++) {
      if (weekCounts[i] >= weekCounts[index]) index = i;
    }
    final count = weekCounts[index];
    final noun = count == 1 ? 'admission' : 'admissions';
    return '${weekLabels[index]} · $count $noun';
  }

  factory DashboardStats.fromPatients(List<Patient> patients, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final today = dateOnly(clock);
    final counts = {for (final status in PatientStatus.values) status: 0};
    var todayCount = 0;
    for (final patient in patients) {
      counts[patient.status] = (counts[patient.status] ?? 0) + 1;
      if (dateOnly(patient.admissionDate) == today) todayCount++;
    }

    final labels = <String>[];
    final week = <int>[];
    for (var offset = 6; offset >= 0; offset--) {
      final day = today.subtract(Duration(days: offset));
      labels.add(DateFormat('EEE').format(day));
      week.add(
        patients
            .where((patient) => dateOnly(patient.admissionDate) == day)
            .length,
      );
    }

    final recent = [...patients]..sort(comparePatients);
    return DashboardStats(
      total: patients.length,
      inCare: patients.where((patient) => patient.status.inCare).length,
      discharged: counts[PatientStatus.discharged] ?? 0,
      todaysAdmissions: todayCount,
      byStatus: counts,
      weekLabels: labels,
      weekCounts: week,
      recent: recent.take(5).toList(),
    );
  }
}
