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
    this.medicalHistory = '',
    this.allergies = '',
    this.medications = '',
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
  final String medicalHistory;
  final String allergies;
  final String medications;

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
      medicalHistory: _text(json['medical_history']),
      allergies: _text(json['allergies']),
      medications: _text(json['medications']),
    );
  }

  Map<String, Object?> toJson() {
    String day(DateTime value) {
      final local = DateTime(value.year, value.month, value.day);
      final month = local.month.toString().padLeft(2, '0');
      final date = local.day.toString().padLeft(2, '0');
      return '${local.year}-$month-$date';
    }

    return {
      'id': id,
      'name': name,
      'gender': gender,
      'date_of_birth': day(dateOfBirth),
      'admission_date': day(admissionDate),
      'status': status.label,
      'phone': phone,
      'email': email,
      'address': address,
      'blood_group': bloodGroup,
      'ward': ward,
      'room': room,
      'attending_doctor': attendingDoctor,
      'diagnosis': diagnosis,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'insurance_provider': insuranceProvider,
      'medical_history': medicalHistory,
      'allergies': allergies,
      'medications': medications,
    };
  }

  Patient copyWith({
    String? name,
    String? gender,
    DateTime? dateOfBirth,
    DateTime? admissionDate,
    PatientStatus? status,
    String? phone,
    String? email,
    String? address,
    String? bloodGroup,
    String? ward,
    String? room,
    String? attendingDoctor,
    String? diagnosis,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? insuranceProvider,
    String? medicalHistory,
    String? allergies,
    String? medications,
  }) {
    return Patient(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      admissionDate: admissionDate ?? this.admissionDate,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      ward: ward ?? this.ward,
      room: room ?? this.room,
      attendingDoctor: attendingDoctor ?? this.attendingDoctor,
      diagnosis: diagnosis ?? this.diagnosis,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
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
