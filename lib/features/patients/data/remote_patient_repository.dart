import 'dart:convert';

import 'package:hospital_dashboard/features/patients/data/patient_repository.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_page_result.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';
import 'package:http/http.dart' as http;

/// Walks `GET /api/v1/patients?page=&page_size=` and filters locally.
///
/// The published contract has no search, status, or detail route, so those
/// behaviours are applied after the pages are collected.
class RemotePatientRepository implements PatientRepository {
  RemotePatientRepository({required String baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      _root = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

  final http.Client _client;
  final String _root;
  List<Patient>? _cache;

  static const _pageSize = 10;
  static const _maxPages = 40;

  @override
  Future<List<Patient>> fetchAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final all = <Patient>[];
    var page = 1;
    var total = 0;
    while (page <= _maxPages) {
      final uri = Uri.parse(
        '$_root/api/v1/patients',
      ).replace(queryParameters: {'page': '$page', 'page_size': '$_pageSize'});
      final body = await _get(uri);
      final result = PatientPageResult.fromJson(body);
      total = result.total;
      if (result.items.isEmpty) break;
      all.addAll(result.items);
      if (all.length >= total) break;
      page++;
    }
    all.sort(comparePatients);
    _cache = all;
    return all;
  }

  @override
  Future<Patient> fetchPatient(int id) async {
    final all = await fetchAll();
    for (final patient in all) {
      if (patient.id == id) return patient;
    }
    throw PatientNotFoundException(id);
  }

  @override
  Future<PatientPageResult> fetchPatients({
    required int page,
    required int pageSize,
    String search = '',
    PatientStatus? status,
  }) async {
    final all = await fetchAll();
    return paginatePatients(
      all,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
    );
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
    } catch (error) {
      throw PatientApiException('Could not reach the patient service.');
    }

    if (response.statusCode != 200) {
      throw PatientApiException(
        'The patient service returned status ${response.statusCode}.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw PatientApiException('The patient response was not valid JSON.');
      }
      return Map<String, dynamic>.from(decoded);
    } on PatientApiException {
      rethrow;
    } catch (_) {
      throw PatientApiException('The patient response could not be read.');
    }
  }
}
