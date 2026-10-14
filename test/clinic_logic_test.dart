import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_dashboard/features/auth/data/auth_repository.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/domain/access_policy.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/features/clinic/domain/form_input.dart';
import 'package:hospital_dashboard/features/clinic/domain/form_rules.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  const policy = AccessPolicy();

  test('patient and doctor forms reject empty and bad contact fields', () {
    expect(
      patientFormError(
        name: '',
        email: 'rahul@cityhospital.org',
        phone: '9876543210',
        dateOfBirth: DateTime(1990, 5, 12),
        gender: 'Male',
        bloodGroup: 'A+',
        address: 'Pune',
        emergencyName: 'Priya',
        emergencyPhone: '9876500000',
      ),
      'Enter the full name.',
    );
    expect(emailRule('not-an-email'), 'Enter a valid email address.');
    expect(phoneRule('12345'), 'Use a 10-digit mobile number.');
    expect(
      personNameRule('rahul1'),
      'Use letters only, at least 2 characters.',
    );
    expect(experienceRule('99'), 'Years of experience cannot be more than 80.');

    const words = CapitalizeWordsFormatter();
    expect(
      words
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: 'anil mehta'),
          )
          .text,
      'Anil Mehta',
    );
    var phone = const TextEditingValue(text: '98ab7654321099');
    for (final formatter in phoneFormatters) {
      phone = formatter.formatEditUpdate(TextEditingValue.empty, phone);
    }
    expect(phone.text, '9876543210');
    expect(
      dateOfBirthRule(DateTime(2999, 1, 1), today: DateTime(2026, 10, 14)),
      'Date of birth cannot be in the future.',
    );
    expect(
      doctorFormError(
        name: 'Neha Kulkarni',
        email: 'neha@cityhospital.org',
        phone: '9822222222',
        specialization: 'Cardiology',
        qualification: 'DM',
        years: '12',
        hospital: 'City Hospital',
        fee: '800',
        days: const [],
        slots: const ['Morning'],
      ),
      'Choose at least one available day.',
    );
  });

  test('access policy keeps patients and chats to the right role', () {
    const patient = Actor(
      role: UserRole.patient,
      email: 'patient@cityhospital.org',
      patientId: 123,
    );
    const doctor = Actor(
      role: UserRole.doctor,
      email: AuthRepository.demoEmail,
      doctorId: 'D-1001',
    );
    const admin = Actor(role: UserRole.admin, email: 'admin@cityhospital.org');

    expect(
      () => policy.readPatient(patient, 124, assignedToActor: false),
      throwsA(isA<ClinicAccessException>()),
    );
    policy.readPatient(patient, 123, assignedToActor: false);
    policy.readPatient(doctor, 123, assignedToActor: true);
    expect(
      () => policy.readPatient(doctor, 130, assignedToActor: false),
      throwsA(isA<ClinicAccessException>()),
    );
    policy.readPatient(admin, 130, assignedToActor: false);
    expect(
      () => policy.readConversation(
        patient,
        patientEmail: 'other@cityhospital.org',
        doctorEmail: AuthRepository.demoEmail,
      ),
      throwsA(isA<ClinicAccessException>()),
    );
    policy.readConversation(
      patient,
      patientEmail: 'patient@cityhospital.org',
      doctorEmail: AuthRepository.demoEmail,
    );
  });

  test('records, assignment, chat, and notifications persist', () async {
    final database = await databaseFactoryMemory.openDatabase('clinic');
    final store = await ClinicStore.open(database: database);
    final admin = await store.authenticate(
      'admin@cityhospital.org',
      AuthRepository.demoPassword,
    );
    final adminActor = Actor(role: admin.role, email: admin.email);
    final created = await store.createPatient(
      adminActor,
      Patient(
        id: 0,
        name: 'Meera Joshi',
        gender: 'Female',
        dateOfBirth: DateTime(1988, 3, 2),
        admissionDate: DateTime(2026, 10, 14),
        status: PatientStatus.admitted,
        phone: '9876512345',
        email: 'meera@cityhospital.org',
        address: 'Pune',
        bloodGroup: 'B+',
        emergencyContactName: 'Asha Joshi',
        emergencyContactPhone: '9876511111',
      ),
    );
    expect(created.id, greaterThan(123));
    expect(
      (await store.getPatient(adminActor, created.id)).name,
      'Meera Joshi',
    );

    final assigned = await store.assignDoctor(
      adminActor,
      patientId: created.id,
      doctorId: ClinicStore.anilId,
    );
    expect(assigned.status, RelationshipStatus.active);
    expect(
      store.assignDoctor(
        adminActor,
        patientId: created.id,
        doctorId: ClinicStore.anilId,
      ),
      throwsA(isA<ClinicException>()),
    );

    final doctor = await store.authenticate(
      AuthRepository.demoEmail,
      AuthRepository.demoPassword,
    );
    final doctorActor = Actor(
      role: doctor.role,
      email: doctor.email,
      doctorId: doctor.doctorId,
    );
    final visible = await store.visiblePatients(doctorActor);
    expect(visible.any((patient) => patient.id == created.id), isTrue);
    expect(visible.any((patient) => patient.id == 140), isFalse);

    final conversation = await store.openConversation(
      doctorActor,
      patientId: 123,
      doctorId: ClinicStore.anilId,
    );
    final sent = await store.sendMessage(
      doctorActor,
      conversationId: conversation.id,
      text: 'How are you feeling?',
    );
    expect(sent.deliveryStatus, DeliveryStatus.delivered);
    final loaded = await store
        .watchMessages(doctorActor, conversation.id)
        .first;
    expect(loaded.single.text, 'How are you feeling?');

    final patient = await store.authenticate(
      'patient@cityhospital.org',
      AuthRepository.demoPassword,
    );
    final patientActor = Actor(
      role: patient.role,
      email: patient.email,
      patientId: patient.patientId,
      doctorId: patient.doctorId,
    );
    expect(await store.unreadMessages(patientActor), 1);
    await store.markConversationRead(patientActor, conversation.id);
    expect(await store.unreadMessages(patientActor), 0);
    final notes = await store.watchNotifications(patientActor).first;
    expect(notes.any((note) => note.title == 'New message'), isTrue);
    await store.markNotificationRead(patientActor, notes.first.id);
    final after = await store.watchNotifications(patientActor).first;
    expect(after.first.isRead, isTrue);

    final request = await store.requestConsultation(
      patientActor,
      patientId: 123,
      doctorId: ClinicStore.anilId,
      scheduledAt: DateTime(2026, 10, 16, 10),
      reason: 'Review',
    );
    final accepted = await store.setAppointmentStatus(
      doctorActor,
      request.id,
      AppointmentStatus.accepted,
    );
    expect(accepted.status, AppointmentStatus.accepted);

    final again = await store.getPatient(adminActor, created.id);
    expect(again.name, 'Meera Joshi');
    await store.close();
  });
}
