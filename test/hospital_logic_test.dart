import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_dashboard/common/format.dart';
import 'package:hospital_dashboard/routing/app_redirect.dart';
import 'package:hospital_dashboard/features/auth/data/auth_repository.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/dashboard/domain/dashboard_stats.dart';
import 'package:hospital_dashboard/features/patients/data/mock_patient_repository.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_page_result.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  group('patient contract', () {
    test('parses the documented list item', () {
      final patient = Patient.fromJson({
        'id': 123,
        'name': 'Rahul Sharma',
        'gender': 'Male',
        'date_of_birth': '1990-05-12',
        'admission_date': '2026-10-10',
        'status': 'Admitted',
      });

      expect(patient.id, 123);
      expect(patient.name, 'Rahul Sharma');
      expect(patient.status, PatientStatus.admitted);
      expect(patient.dateOfBirth, DateTime(1990, 5, 12));
    });

    test('parses a page payload', () {
      final page = PatientPageResult.fromJson({
        'items': [
          {
            'id': 123,
            'name': 'Rahul Sharma',
            'gender': 'Male',
            'date_of_birth': '1990-05-12',
            'admission_date': '2026-10-10',
            'status': 'Admitted',
          },
        ],
        'total': 1,
        'page': 1,
        'page_size': 10,
      });

      expect(page.total, 1);
      expect(page.items.single.name, 'Rahul Sharma');
    });
  });

  group('mock patients', () {
    final clock = DateTime(2026, 10, 14, 9);

    MockPatientRepository repo() {
      return MockPatientRepository(latency: Duration.zero, clock: clock);
    }

    test('pages, searches, and filters', () async {
      final patients = repo();
      final first = await patients.fetchPatients(page: 1, pageSize: 10);
      final second = await patients.fetchPatients(page: 2, pageSize: 10);

      expect(first.total, 42);
      expect(first.items, hasLength(10));
      expect(second.items.first.id, isNot(first.items.first.id));

      final byName = await patients.fetchPatients(
        page: 1,
        pageSize: 10,
        search: 'rahul',
      );
      expect(byName.items.single.id, 123);

      final byId = await patients.fetchPatients(
        page: 1,
        pageSize: 10,
        search: '123',
      );
      expect(byId.items.single.name, 'Rahul Sharma');

      final admitted = await patients.fetchPatients(
        page: 1,
        pageSize: 10,
        status: PatientStatus.admitted,
      );
      expect(
        admitted.items.every(
          (patient) => patient.status == PatientStatus.admitted,
        ),
        isTrue,
      );

      final empty = await patients.fetchPatients(
        page: 1,
        pageSize: 10,
        search: 'zzzz',
      );
      expect(empty.items, isEmpty);
      expect(empty.total, 0);
    });

    test('missing charts throw a not-found error', () async {
      expect(
        repo().fetchPatient(9999),
        throwsA(isA<PatientNotFoundException>()),
      );
    });

    test('simulated outages surface an API error', () async {
      final patients = MockPatientRepository(
        latency: Duration.zero,
        simulateError: true,
        clock: clock,
      );
      expect(patients.fetchAll(), throwsA(isA<PatientApiException>()));
    });

    test('dashboard totals stay consistent', () async {
      final patients = await repo().fetchAll();
      final stats = DashboardStats.fromPatients(patients, now: clock);

      expect(stats.total, 42);
      expect(stats.inCare + stats.discharged, stats.total);
      expect(stats.todaysAdmissions, 3);
      expect(stats.recent, hasLength(5));
      expect(
        stats.recent.every(
          (patient) => !patient.admissionDate.isAfter(
            dateOnly(clock).add(const Duration(days: 1)),
          ),
        ),
        isTrue,
      );
    });
  });

  group('staff sign in', () {
    test('accepts the demo account and rejects anything else', () async {
      final auth = AuthRepository(latency: Duration.zero);
      expect(
        await auth.signIn('  Doctor@CityHospital.org ', 'Ward1234'),
        'doctor@cityhospital.org',
      );
      expect(
        auth.signIn(AuthRepository.demoEmail, 'wrong-password'),
        throwsA(isA<AuthException>()),
      );
    });

    test('validates the form before a request is made', () {
      expect(validateEmail(''), 'Enter your work email.');
      expect(validateEmail('not-an-email'), 'Enter a valid email address.');
      expect(validateEmail('doctor@cityhospital.org'), isNull);
      expect(validatePassword(''), 'Enter your password.');
      expect(validatePassword('short'), 'Use at least 8 characters.');
      expect(validatePassword('Ward1234'), isNull);
    });
  });

  group('browser navigation', () {
    test('keeps a deep link through the boot and login gates', () {
      const booting = AuthState.booting();
      expect(
        resolveRedirect(auth: booting, uri: Uri.parse('/patients/123')),
        '/boot?from=%2Fpatients%2F123',
      );
      expect(
        resolveRedirect(
          auth: booting,
          uri: Uri.parse('/boot?from=%2Fpatients%2F123'),
        ),
        isNull,
      );

      final signedOut = AuthState.signedOut();
      expect(
        resolveRedirect(
          auth: signedOut,
          uri: Uri.parse('/boot?from=%2Fpatients%2F123'),
        ),
        '/login?from=%2Fpatients%2F123',
      );
      expect(
        resolveRedirect(
          auth: signedOut,
          uri: Uri.parse('/login?from=%2Fpatients%2F123'),
        ),
        isNull,
      );

      final signedIn = AuthState.signedIn('doctor@cityhospital.org');
      expect(
        resolveRedirect(
          auth: signedIn,
          uri: Uri.parse('/login?from=%2Fpatients%2F123'),
        ),
        '/patients/123',
      );
      expect(
        resolveRedirect(auth: signedIn, uri: Uri.parse('/patients/123')),
        isNull,
      );
      expect(
        resolveRedirect(
          auth: signedIn,
          uri: Uri.parse('/login?from=https://evil.example'),
        ),
        '/dashboard',
      );
    });
  });
}
