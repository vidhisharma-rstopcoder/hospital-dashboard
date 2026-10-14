import 'package:hospital_dashboard/common/format.dart';
import 'package:hospital_dashboard/features/patients/data/patient_repository.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_page_result.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';

class MockPatientRepository implements PatientRepository {
  MockPatientRepository({
    this.latency = const Duration(milliseconds: 680),
    this.simulateError = false,
    DateTime? clock,
  }) : _patients = buildPatientCatalog(clock ?? DateTime.now());

  final Duration latency;
  final bool simulateError;
  final List<Patient> _patients;

  @override
  Future<List<Patient>> fetchAll() async {
    await _pause();
    return List<Patient>.unmodifiable(_patients);
  }

  @override
  Future<Patient> fetchPatient(int id) async {
    await _pause();
    for (final patient in _patients) {
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
    await _pause();
    return paginatePatients(
      _patients,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
    );
  }

  Future<void> _pause() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (simulateError) {
      throw PatientApiException(
        'The patient service did not respond. Try again.',
      );
    }
  }
}

List<Patient> buildPatientCatalog(DateTime clock) {
  final today = dateOnly(clock);
  assert(_roster.length == _admissionDaysAgo.length);
  final patients = <Patient>[];
  for (var i = 0; i < _roster.length; i++) {
    final person = _roster[i];
    final id = 123 + i;
    final status = _statusFor(i);
    final ward = _wardFor(status, i);
    final lastName = person.name.split(' ').last;
    patients.add(
      Patient(
        id: id,
        name: person.name,
        gender: person.gender,
        dateOfBirth: i == 0
            ? DateTime(1990, 5, 12)
            : DateTime(1948 + (i * 7) % 62, (i % 12) + 1, (i % 27) + 1),
        admissionDate: today.subtract(Duration(days: _admissionDaysAgo[i])),
        status: status,
        phone: _phone(id),
        email: _email(person.name, id),
        address: '${18 + i}, ${_streets[i % _streets.length]}, ${person.city}',
        bloodGroup: _bloodGroups[i % _bloodGroups.length],
        ward: ward,
        room: '${_wardCode(ward)}-${110 + i}',
        attendingDoctor: _doctors[i % _doctors.length],
        diagnosis: _diagnoses[i % _diagnoses.length],
        emergencyContactName:
            '${person.gender == 'Female' ? 'Arun' : 'Meera'} $lastName',
        emergencyContactPhone: _phone(id + 80),
        insuranceProvider: _insurers[i % _insurers.length],
      ),
    );
  }
  return patients;
}

PatientStatus _statusFor(int index) {
  if (index == 0 || index == 1) return PatientStatus.admitted;
  if (index == 2) return PatientStatus.critical;
  const cycle = [
    PatientStatus.admitted,
    PatientStatus.discharged,
    PatientStatus.observation,
    PatientStatus.admitted,
    PatientStatus.discharged,
    PatientStatus.critical,
    PatientStatus.admitted,
    PatientStatus.discharged,
  ];
  return cycle[index % cycle.length];
}

String _wardFor(PatientStatus status, int index) {
  if (status == PatientStatus.critical) return 'Intensive Care';
  if (status == PatientStatus.observation) return 'Step-down Unit';
  return _wards[index % _wards.length];
}

String _wardCode(String ward) {
  final parts = ward.split(' ').where((part) => part.isNotEmpty);
  return parts.map((part) => part[0]).take(3).join().toUpperCase();
}

String _phone(int seed) {
  final digits = (9800000000 + (seed * 137) % 100000000).toString();
  return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
}

String _email(String name, int id) {
  final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '.');
  return '$slug$id@cityhospital.org';
}

const _admissionDaysAgo = <int>[
  0,
  0,
  0,
  1,
  1,
  1,
  2,
  2,
  2,
  2,
  3,
  3,
  3,
  3,
  3,
  3,
  4,
  4,
  4,
  4,
  5,
  5,
  5,
  5,
  5,
  6,
  6,
  6,
  9,
  12,
  15,
  18,
  21,
  25,
  30,
  36,
  42,
  50,
  60,
  75,
  90,
  120,
];

const _roster = <({String name, String gender, String city})>[
  (name: 'Rahul Sharma', gender: 'Male', city: 'Pune'),
  (name: 'Ananya Iyer', gender: 'Female', city: 'Kochi'),
  (name: 'Kabir Menon', gender: 'Male', city: 'Jaipur'),
  (name: 'Sofia Rahman', gender: 'Female', city: 'Surat'),
  (name: 'Arjun Patel', gender: 'Male', city: 'Lucknow'),
  (name: 'Meera Nair', gender: 'Female', city: 'Indore'),
  (name: 'Vikram Desai', gender: 'Male', city: 'Nagpur'),
  (name: 'Leela Krishnan', gender: 'Female', city: 'Bhopal'),
  (name: 'Neel Joshi', gender: 'Male', city: 'Pune'),
  (name: 'Aisha Khan', gender: 'Female', city: 'Kochi'),
  (name: 'Rohan Gupta', gender: 'Male', city: 'Jaipur'),
  (name: 'Diya Kapoor', gender: 'Female', city: 'Surat'),
  (name: 'Imran Qureshi', gender: 'Male', city: 'Lucknow'),
  (name: 'Sara Dsouza', gender: 'Female', city: 'Indore'),
  (name: 'Aditya Rao', gender: 'Male', city: 'Nagpur'),
  (name: 'Nisha Banerjee', gender: 'Female', city: 'Bhopal'),
  (name: 'Farhan Ali', gender: 'Male', city: 'Pune'),
  (name: 'Priya Kulkarni', gender: 'Female', city: 'Kochi'),
  (name: 'Harsh Vardhan', gender: 'Male', city: 'Jaipur'),
  (name: 'Tara Singh', gender: 'Female', city: 'Surat'),
  (name: 'Dev Malhotra', gender: 'Male', city: 'Lucknow'),
  (name: 'Ishita Bose', gender: 'Female', city: 'Indore'),
  (name: 'Omar Farooq', gender: 'Male', city: 'Nagpur'),
  (name: 'Kiara Shah', gender: 'Female', city: 'Bhopal'),
  (name: 'Yash Verma', gender: 'Male', city: 'Pune'),
  (name: 'Anjali Menon', gender: 'Female', city: 'Kochi'),
  (name: 'Suresh Pillai', gender: 'Male', city: 'Jaipur'),
  (name: 'Fatima Noor', gender: 'Female', city: 'Surat'),
  (name: 'Nikhil Jain', gender: 'Male', city: 'Lucknow'),
  (name: 'Rhea Chawla', gender: 'Female', city: 'Indore'),
  (name: 'Abdul Karim', gender: 'Male', city: 'Nagpur'),
  (name: 'Lavanya Reddy', gender: 'Female', city: 'Bhopal'),
  (name: 'Joseph Mathew', gender: 'Male', city: 'Pune'),
  (name: 'Harpreet Kaur', gender: 'Female', city: 'Kochi'),
  (name: 'Vivek Nambiar', gender: 'Male', city: 'Jaipur'),
  (name: 'Sana Mirza', gender: 'Female', city: 'Surat'),
  (name: 'Karan Bhatia', gender: 'Male', city: 'Lucknow'),
  (name: 'Maya Fernandes', gender: 'Female', city: 'Indore'),
  (name: 'Arvind Chauhan', gender: 'Male', city: 'Nagpur'),
  (name: 'Noor Jahan', gender: 'Female', city: 'Bhopal'),
  (name: 'Elias Varghese', gender: 'Male', city: 'Pune'),
  (name: 'Amrita Sen', gender: 'Female', city: 'Kochi'),
];

const _wards = [
  'General Medicine',
  'Cardiology',
  'Orthopedics',
  'Pediatrics',
  'Neurology',
  'Oncology',
];

const _doctors = [
  'Dr. Meera Iyer',
  'Dr. Arjun Patel',
  'Dr. Sofia Rahman',
  'Dr. Kabir Menon',
  'Dr. Elena Voss',
  'Dr. Harish Rao',
];

const _diagnoses = [
  'Community-acquired pneumonia',
  'Unstable angina',
  'Closed fracture of the radius',
  'Acute gastroenteritis',
  'Type 2 diabetes with dehydration',
  'Migraine with aura',
  'Post-operative wound review',
  'Asthma exacerbation',
  'Dengue fever observation',
  'Congestive heart failure',
  'Renal colic',
  'Anaemia under investigation',
];

const _bloodGroups = ['A+', 'O+', 'B+', 'AB+', 'A-', 'O-', 'B-', 'AB-'];

const _insurers = [
  'Star Health',
  'HDFC Ergo',
  'ICICI Lombard',
  'New India Assurance',
  'Self-pay',
];

const _streets = [
  'MG Road',
  'Lake View',
  'Station Road',
  'Civil Lines',
  'Park Street',
  'Residency Road',
  'Hill Road',
  'Ring Road',
];
