import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';

class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.admissionDate,
    required this.status,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.bloodGroup = '',
    this.ward = '',
    this.room = '',
    this.attendingDoctor = '',
    this.diagnosis = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.insuranceProvider = '',
  });

  final int id;
  final String name;
  final String gender;
  final DateTime dateOfBirth;
  final DateTime admissionDate;
  final PatientStatus status;
  final String phone;
  final String email;
  final String address;
  final String bloodGroup;
  final String ward;
  final String room;
  final String attendingDoctor;
  final String diagnosis;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String insuranceProvider;

  int ageOn(DateTime day) {
    final today = DateTime(day.year, day.month, day.day);
    var age = today.year - dateOfBirth.year;
    final birthday = DateTime(today.year, dateOfBirth.month, dateOfBirth.day);
    if (birthday.isAfter(today)) age--;
    return age;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final gender = json['gender'];
    final dob = json['date_of_birth'];
    final admission = json['admission_date'];
    final status = json['status'];
    if (id is! num ||
        name is! String ||
        gender is! String ||
        dob is! String ||
        admission is! String ||
        status is! String) {
      throw PatientApiException('The patient record was incomplete.');
    }

    return Patient(
      id: id.toInt(),
      name: name,
      gender: gender,
      dateOfBirth: _parseDate(dob),
      admissionDate: _parseDate(admission),
      status: PatientStatus.parse(status),
      phone: _text(json['phone']),
      email: _text(json['email']),
      address: _text(json['address']),
      bloodGroup: _text(json['blood_group']),
      ward: _text(json['ward']),
      room: _text(json['room']),
      attendingDoctor: _text(json['attending_doctor']),
      diagnosis: _text(json['diagnosis']),
      emergencyContactName: _text(json['emergency_contact_name']),
      emergencyContactPhone: _text(json['emergency_contact_phone']),
      insuranceProvider: _text(json['insurance_provider']),
    );
  }

  static DateTime _parseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } on FormatException {
      throw PatientApiException('A patient date could not be read.');
    }
  }

  static String _text(Object? value) => value is String ? value : '';
}

int comparePatients(Patient a, Patient b) {
  final byDate = b.admissionDate.compareTo(a.admissionDate);
  if (byDate != 0) return byDate;
  return b.id.compareTo(a.id);
}
