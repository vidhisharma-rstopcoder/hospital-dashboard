import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';

class PatientPageResult {
  const PatientPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<Patient> items;
  final int total;
  final int page;
  final int pageSize;

  factory PatientPageResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw PatientApiException(
        'The patient list was not in the expected shape.',
      );
    }
    final items = rawItems.map((item) {
      if (item is! Map) {
        throw PatientApiException(
          'A patient record was not in the expected shape.',
        );
      }
      return Patient.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    return PatientPageResult(
      items: items,
      total: _number(json['total']) ?? items.length,
      page: _number(json['page']) ?? 1,
      pageSize:
          _number(json['page_size']) ?? (items.isEmpty ? 10 : items.length),
    );
  }

  static int? _number(Object? value) => value is num ? value.toInt() : null;
}

PatientPageResult paginatePatients(
  List<Patient> source, {
  required int page,
  required int pageSize,
  String search = '',
  PatientStatus? status,
}) {
  final safePageSize = pageSize < 1 ? 10 : pageSize;
  final needle = search.trim().toLowerCase();
  final filtered = source.where((patient) {
    final matchesStatus = status == null || patient.status == status;
    final matchesSearch =
        needle.isEmpty ||
        patient.name.toLowerCase().contains(needle) ||
        patient.id.toString().contains(needle);
    return matchesStatus && matchesSearch;
  }).toList()..sort(comparePatients);

  final total = filtered.length;
  final requestedPage = page < 1 ? 1 : page;
  final start = (requestedPage - 1) * safePageSize;
  final items = start >= total
      ? const <Patient>[]
      : filtered.skip(start).take(safePageSize).toList();

  return PatientPageResult(
    items: items,
    total: total,
    page: requestedPage,
    pageSize: safePageSize,
  );
}
