import 'package:hospital_dashboard/features/auth/data/auth_repository.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_bus.dart';
import 'package:hospital_dashboard/features/clinic/data/password_hash.dart';
import 'package:hospital_dashboard/features/clinic/data/platform_database.dart';
import 'package:hospital_dashboard/features/clinic/domain/access_policy.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/features/patients/data/mock_patient_repository.dart';
import 'package:hospital_dashboard/features/patients/domain/patient.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_page_result.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

final clinicStoreProvider = FutureProvider<ClinicStore>((ref) async {
  final store = await ClinicStore.open();
  ref.onDispose(store.close);
  return store;
});

class ClinicStore {
  ClinicStore._(this._db, this._bus);

  final Database _db;
  final ClinicBus _bus;
  final AccessPolicy _policy = const AccessPolicy();
  var _sequence = 0;

  static final _patients = intMapStoreFactory.store('patients');
  static final _doctors = stringMapStoreFactory.store('doctors');
  static final _users = stringMapStoreFactory.store('users');
  static final _rels = stringMapStoreFactory.store('relationships');
  static final _appointments = stringMapStoreFactory.store('appointments');
  static final _conversations = stringMapStoreFactory.store('conversations');
  static final _messages = stringMapStoreFactory.store('messages');
  static final _notes = stringMapStoreFactory.store('notifications');
  static final _meta = stringMapStoreFactory.store('meta');

  static const anilId = 'D-1001';

  Stream<String> get changes => _bus.events;

  static Future<ClinicStore> open({Database? database}) async {
    final db = database ?? await openClinicDatabase();
    final store = ClinicStore._(db, openClinicBus());
    await store._seed();
    return store;
  }

  Future<void> close() async {
    _bus.close();
    await _db.close();
  }

  Future<ClinicUser> authenticate(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final user = await userByEmail(normalized);
    if (user == null || user.passwordHash != hashPassword(password)) {
      throw AuthException('Email or password is wrong.');
    }
    return user;
  }

  Future<ClinicUser?> userByEmail(String email) async {
    final raw = await _users.record(email.trim().toLowerCase()).get(_db);
    if (raw == null) return null;
    return ClinicUser.fromJson(raw);
  }

  Future<PatientPageResult> pagePatients(
    Actor actor, {
    required int page,
    required int pageSize,
    String search = '',
    PatientStatus? status,
  }) async {
    final visible = await _visiblePatients(actor);
    return paginatePatients(
      visible,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
    );
  }

  Future<List<Patient>> visiblePatients(Actor actor) => _visiblePatients(actor);

  Future<Patient> getPatient(Actor actor, int id) async {
    final patient = await _patientOrThrow(id);
    final assigned = await _doctorAssigned(actor, id);
    _policy.readPatient(actor, id, assignedToActor: assigned);
    return patient;
  }

  Future<Patient> createPatient(Actor actor, Patient draft) async {
    _policy.createPatient(actor);
    final keys = await _patients.findKeys(_db);
    final id = keys.isEmpty ? 123 : keys.reduce((a, b) => a > b ? a : b) + 1;
    final patient = Patient(
      id: id,
      name: draft.name.trim(),
      gender: draft.gender,
      dateOfBirth: draft.dateOfBirth,
      admissionDate: DateTime.now(),
      status: draft.status,
      phone: _digits(draft.phone),
      email: draft.email.trim().toLowerCase(),
      address: draft.address.trim(),
      bloodGroup: draft.bloodGroup,
      ward: draft.ward,
      room: draft.room,
      attendingDoctor: draft.attendingDoctor,
      diagnosis: draft.diagnosis.trim(),
      emergencyContactName: draft.emergencyContactName.trim(),
      emergencyContactPhone: _digits(draft.emergencyContactPhone),
      insuranceProvider: draft.insuranceProvider.trim(),
      medicalHistory: draft.medicalHistory.trim(),
      allergies: draft.allergies.trim(),
      medications: draft.medications.trim(),
    );
    await _patients.record(id).put(_db, patient.toJson());
    await _notify(
      email: _adminEmail,
      title: 'Patient registered',
      message: '${patient.name} was added to the ward list.',
      route: '/patients/$id',
    );
    _bus.publish('patients');
    return patient;
  }

  Future<Patient> updatePatient(Actor actor, Patient draft) async {
    await _patientOrThrow(draft.id);
    final assigned = await _doctorAssigned(actor, draft.id);
    _policy.writePatient(actor, patientId: draft.id, assignedToActor: assigned);
    final saved = draft.copyWith(
      name: draft.name.trim(),
      phone: _digits(draft.phone),
      email: draft.email.trim().toLowerCase(),
      emergencyContactPhone: _digits(draft.emergencyContactPhone),
    );
    await _patients.record(saved.id).put(_db, saved.toJson());
    _bus.publish('patients');
    return saved;
  }

  Future<void> deletePatient(Actor actor, int id) async {
    _policy.deletePatient(actor);
    await _patientOrThrow(id);
    final now = DateTime.now();
    for (final rel in await _relsForPatient(id)) {
      if (rel.status == RelationshipStatus.inactive) continue;
      await _putRel(_inactive(rel, now));
    }
    for (final appointment in await _appointmentsForPatient(id)) {
      if (appointment.status == AppointmentStatus.cancelled ||
          appointment.status == AppointmentStatus.rejected) {
        continue;
      }
      await _putAppointment(
        _appointmentWith(appointment, AppointmentStatus.cancelled, now),
      );
    }
    await _patients.record(id).delete(_db);
    await _notify(
      email: _adminEmail,
      title: 'Patient removed',
      message: 'Patient $id was removed. Assignments were closed.',
      route: '/patients',
    );
    _bus.publish('patients');
  }

  Future<List<Doctor>> listDoctors(
    Actor actor, {
    String search = '',
    String? specialization,
  }) async {
    final all = await _allDoctors();
    final needle = search.trim().toLowerCase();
    Iterable<Doctor> visible = all;
    if (actor.role == UserRole.patient) {
      final ids = await _activeDoctorIdsForPatient(actor.patientId);
      visible = all.where((doctor) => ids.contains(doctor.id));
    }
    return visible.where((doctor) {
      final matchesSpec =
          specialization == null ||
          specialization.isEmpty ||
          specialization == 'All' ||
          doctor.specialization == specialization;
      final matchesSearch =
          needle.isEmpty ||
          doctor.name.toLowerCase().contains(needle) ||
          doctor.specialization.toLowerCase().contains(needle) ||
          doctor.id.toLowerCase().contains(needle);
      return matchesSpec && matchesSearch;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<Doctor> getDoctor(Actor actor, String id) async {
    final doctor = await _doctorOrThrow(id);
    final assigned = actor.role == UserRole.patient
        ? (await _activeDoctorIdsForPatient(actor.patientId)).contains(id)
        : true;
    _policy.readDoctor(actor, assignedToActor: assigned);
    return doctor;
  }

  Future<Doctor> createDoctor(Actor actor, Doctor draft) async {
    _policy.createDoctor(actor);
    final keys = await _doctors.findKeys(_db);
    var max = 1000;
    for (final key in keys) {
      final number = int.tryParse(key.replaceFirst('D-', ''));
      if (number != null && number > max) max = number;
    }
    final doctor = Doctor(
      id: 'D-${max + 1}',
      name: draft.name.trim(),
      email: draft.email.trim().toLowerCase(),
      phone: _digits(draft.phone),
      specialization: draft.specialization.trim(),
      qualification: draft.qualification.trim(),
      yearsExperience: draft.yearsExperience,
      hospital: draft.hospital.trim(),
      consultationFee: draft.consultationFee,
      availableDays: draft.availableDays,
      timeSlots: draft.timeSlots,
      bio: draft.bio.trim(),
      photoDataUrl: draft.photoDataUrl,
    );
    await _doctors.record(doctor.id).put(_db, doctor.toJson());
    _bus.publish('doctors');
    return doctor;
  }

  Future<Doctor> updateDoctor(Actor actor, Doctor draft) async {
    await _doctorOrThrow(draft.id);
    _policy.writeDoctor(actor, draft.id);
    final saved = draft.copyWith(
      name: draft.name.trim(),
      email: draft.email.trim().toLowerCase(),
      phone: _digits(draft.phone),
    );
    await _doctors.record(saved.id).put(_db, saved.toJson());
    _bus.publish('doctors');
    return saved;
  }

  Future<void> deleteDoctor(Actor actor, String id) async {
    _policy.createDoctor(actor);
    final doctor = await _doctorOrThrow(id);
    final now = DateTime.now();
    for (final rel in await _allRels()) {
      if (rel.doctorId != id || rel.status == RelationshipStatus.inactive) {
        continue;
      }
      await _putRel(_inactive(rel, now));
      final patient = await _findPatient(rel.patientId);
      if (patient != null && patient.attendingDoctor == doctor.name) {
        await _patients
            .record(patient.id)
            .put(_db, patient.copyWith(attendingDoctor: '').toJson());
      }
    }
    await _doctors.record(id).delete(_db);
    _bus.publish('doctors');
  }

  Future<PatientDoctorRelationship?> activeRelationship(int patientId) async {
    final rels = await _relsForPatient(patientId);
    for (final rel in rels) {
      if (rel.status == RelationshipStatus.active) return rel;
    }
    return null;
  }

  Future<List<Patient>> patientsForDoctor(Actor actor, String doctorId) async {
    if (!actor.isAdmin && actor.doctorId != doctorId) {
      throw ClinicAccessException('You cannot open this doctor\'s list.');
    }
    final ids = (await _allRels())
        .where(
          (rel) =>
              rel.doctorId == doctorId &&
              rel.status == RelationshipStatus.active,
        )
        .map((rel) => rel.patientId)
        .toSet();
    final patients = await _allPatients();
    return patients.where((patient) => ids.contains(patient.id)).toList();
  }

  Future<PatientDoctorRelationship> assignDoctor(
    Actor actor, {
    required int patientId,
    required String doctorId,
  }) async {
    _policy.assignDoctor(actor);
    final patient = await _patientOrThrow(patientId);
    final doctor = await _doctorOrThrow(doctorId);
    final existing = await _relsForPatient(patientId);
    if (existing.any(
      (rel) =>
          rel.doctorId == doctorId && rel.status == RelationshipStatus.active,
    )) {
      throw ClinicException('This doctor is already assigned.');
    }
    final now = DateTime.now();
    for (final rel in existing) {
      if (rel.status == RelationshipStatus.active) {
        await _putRel(_inactive(rel, now));
      }
    }
    final created = PatientDoctorRelationship(
      id: _id('rel'),
      patientId: patientId,
      doctorId: doctorId,
      status: RelationshipStatus.active,
      assignedAt: now,
      updatedAt: now,
    );
    await _putRel(created);
    await _patients
        .record(patientId)
        .put(_db, patient.copyWith(attendingDoctor: doctor.name).toJson());
    await _pointPatientUser(patientId, doctorId);
    final patientUser = await _userForPatient(patientId);
    await _notify(
      email: patientUser?.email ?? '',
      title: 'Doctor assigned',
      message: '${doctor.name} is now your doctor.',
      route: '/patients/$patientId',
    );
    await _notify(
      email: doctor.email,
      title: 'Patient assigned',
      message: '${patient.name} is on your list.',
      route: '/patients/$patientId',
    );
    _bus.publish('patients');
    return created;
  }

  Future<List<Appointment>> listAppointments(Actor actor) async {
    final all = await _allAppointments();
    if (actor.isAdmin) return all;
    if (actor.role == UserRole.patient) {
      return all.where((item) => item.patientId == actor.patientId).toList();
    }
    return all.where((item) => item.doctorId == actor.doctorId).toList();
  }

  Future<Appointment> requestConsultation(
    Actor actor, {
    required int patientId,
    required String doctorId,
    required DateTime scheduledAt,
    required String reason,
  }) async {
    _policy.requestConsultation(actor, patientId);
    final active = await activeRelationship(patientId);
    if (active == null || active.doctorId != doctorId) {
      throw ClinicException(
        'Assign a doctor before requesting a consultation.',
      );
    }
    final open = (await _appointmentsForPatient(patientId)).any(
      (item) =>
          item.doctorId == doctorId &&
          item.status == AppointmentStatus.requested,
    );
    if (open) {
      throw ClinicException('A consultation request is already waiting.');
    }
    final now = DateTime.now();
    final appointment = Appointment(
      id: _id('apt'),
      patientId: patientId,
      doctorId: doctorId,
      status: AppointmentStatus.requested,
      scheduledAt: scheduledAt,
      reason: reason.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _putAppointment(appointment);
    final doctor = await _doctorOrThrow(doctorId);
    final patient = await _patientOrThrow(patientId);
    await _notify(
      email: doctor.email,
      title: 'Consultation request',
      message: '${patient.name} asked for a consultation.',
      route: '/appointments',
    );
    _bus.publish('appointments');
    return appointment;
  }

  Future<Appointment> setAppointmentStatus(
    Actor actor,
    String id,
    AppointmentStatus status,
  ) async {
    final current = await _appointmentOrThrow(id);
    final assigned = actor.doctorId == current.doctorId;
    if (status == AppointmentStatus.cancelled &&
        actor.role == UserRole.patient &&
        actor.patientId == current.patientId) {
      // The patient who owns the request may cancel it.
    } else {
      _policy.decideConsultation(actor, assignedToActor: assigned);
    }
    if (current.status == AppointmentStatus.rejected ||
        current.status == AppointmentStatus.cancelled) {
      throw ClinicException('This consultation is already closed.');
    }
    final updated = _appointmentWith(current, status, DateTime.now());
    await _putAppointment(updated);
    final patientUser = await _userForPatient(current.patientId);
    final doctor = await _doctorOrThrow(current.doctorId);
    final title = switch (status) {
      AppointmentStatus.accepted => 'Consultation accepted',
      AppointmentStatus.rejected => 'Consultation declined',
      AppointmentStatus.cancelled => 'Consultation cancelled',
      AppointmentStatus.requested => 'Consultation updated',
    };
    await _notify(
      email: patientUser?.email ?? '',
      title: title,
      message: 'Your consultation is now ${status.name}.',
      route: '/appointments',
    );
    if (actor.email != doctor.email) {
      await _notify(
        email: doctor.email,
        title: title,
        message: 'A consultation on your list was updated.',
        route: '/appointments',
      );
    }
    _bus.publish('appointments');
    return updated;
  }

  Future<Conversation> openConversation(
    Actor actor, {
    required int patientId,
    required String doctorId,
  }) async {
    final active = await activeRelationship(patientId);
    if (active == null || active.doctorId != doctorId) {
      throw ClinicException('Chat is available after a doctor is assigned.');
    }
    final patientUser = await _userForPatient(patientId);
    final doctor = await _doctorOrThrow(doctorId);
    final patientEmail = patientUser?.email ?? '';
    final doctorEmail = doctor.email;
    _policy.readConversation(
      actor,
      patientEmail: patientEmail,
      doctorEmail: doctorEmail,
    );
    final id = 'c-$patientId-$doctorId';
    final existing = await _conversations.record(id).get(_db);
    if (existing != null) return Conversation.fromJson(existing);
    final created = Conversation(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      patientEmail: patientEmail,
      doctorEmail: doctorEmail,
    );
    await _conversations.record(id).put(_db, created.toJson());
    return created;
  }

  Stream<List<ChatMessage>> watchMessages(
    Actor actor,
    String conversationId,
  ) async* {
    await _requireConversation(actor, conversationId);
    yield await _messagesFor(conversationId);
    await for (final topic in _bus.events) {
      if (topic == 'chat:$conversationId') {
        yield await _messagesFor(conversationId);
      }
    }
  }

  Future<ChatMessage> sendMessage(
    Actor actor, {
    required String conversationId,
    required String text,
  }) async {
    final conversation = await _requireConversation(actor, conversationId);
    final body = text.trim();
    if (body.isEmpty) throw ClinicException('Write a message first.');
    final sender = actor.email.toLowerCase();
    final patientEmail = conversation.patientEmail.toLowerCase();
    final doctorEmail = conversation.doctorEmail.toLowerCase();
    if (sender != patientEmail && sender != doctorEmail) {
      throw ClinicAccessException('You cannot send in this conversation.');
    }
    final receiver = sender == patientEmail ? doctorEmail : patientEmail;
    final message = ChatMessage(
      id: _id('m'),
      conversationId: conversationId,
      senderId: sender,
      receiverId: receiver,
      text: body,
      createdAt: DateTime.now(),
      deliveryStatus: DeliveryStatus.delivered,
    );
    await _messages.record(message.id).put(_db, message.toJson());
    await _notify(
      email: receiver,
      title: 'New message',
      message: body,
      route: '/messages/$conversationId',
    );
    _bus.publish('chat:$conversationId');
    return message;
  }

  Future<void> markConversationRead(Actor actor, String conversationId) async {
    await _requireConversation(actor, conversationId);
    final now = DateTime.now();
    for (final message in await _messagesFor(conversationId)) {
      if (message.receiverId != actor.email.toLowerCase() ||
          message.readAt != null) {
        continue;
      }
      final read = ChatMessage(
        id: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        receiverId: message.receiverId,
        text: message.text,
        createdAt: message.createdAt,
        deliveryStatus: DeliveryStatus.read,
        readAt: now,
      );
      await _messages.record(read.id).put(_db, read.toJson());
    }
    _bus.publish('chat:$conversationId');
    _bus.publish('unread');
  }

  Future<int> unreadMessages(Actor actor) async {
    final email = actor.email.toLowerCase();
    final all = await _messages.find(_db);
    return all
        .map((record) => ChatMessage.fromJson(record.value))
        .where(
          (message) => message.receiverId == email && message.readAt == null,
        )
        .length;
  }

  Stream<List<ClinicNotification>> watchNotifications(Actor actor) async* {
    yield await _notesFor(actor.email);
    await for (final topic in _bus.events) {
      if (topic == 'notify:${actor.email.toLowerCase()}' ||
          topic == 'notify-read:${actor.email.toLowerCase()}') {
        yield await _notesFor(actor.email);
      }
    }
  }

  Future<void> markNotificationRead(Actor actor, String id) async {
    final raw = await _notes.record(id).get(_db);
    if (raw == null) return;
    final note = ClinicNotification.fromJson(raw);
    if (note.userEmail != actor.email.toLowerCase()) {
      throw ClinicAccessException('You cannot change this notification.');
    }
    if (note.isRead) return;
    final read = ClinicNotification(
      id: note.id,
      userEmail: note.userEmail,
      title: note.title,
      message: note.message,
      createdAt: note.createdAt,
      route: note.route,
      readAt: DateTime.now(),
    );
    await _notes.record(id).put(_db, read.toJson());
    _bus.publish('notify-read:${actor.email.toLowerCase()}');
  }

  Future<void> markAllNotificationsRead(Actor actor) async {
    final now = DateTime.now();
    for (final note in await _notesFor(actor.email)) {
      if (note.isRead) continue;
      await _notes
          .record(note.id)
          .put(
            _db,
            ClinicNotification(
              id: note.id,
              userEmail: note.userEmail,
              title: note.title,
              message: note.message,
              createdAt: note.createdAt,
              route: note.route,
              readAt: now,
            ).toJson(),
          );
    }
    _bus.publish('notify-read:${actor.email.toLowerCase()}');
  }

  Future<ClinicSummary> summary(Actor actor) async {
    final patients = await _visiblePatients(actor);
    final doctors = await listDoctors(actor);
    final rels = await _visibleRels(actor);
    final appointments = await listAppointments(actor);
    final now = DateTime.now();
    final notes = await _notesFor(actor.email);
    return ClinicSummary(
      totalPatients: patients.length,
      totalDoctors: actor.isAdmin ? doctors.length : doctors.length,
      activeRelationships: rels
          .where((rel) => rel.status == RelationshipStatus.active)
          .length,
      upcomingAppointments: appointments
          .where(
            (item) =>
                item.status == AppointmentStatus.accepted &&
                !item.scheduledAt.isBefore(now),
          )
          .length,
      pendingRequests: appointments
          .where((item) => item.status == AppointmentStatus.requested)
          .length,
      unreadMessages: await unreadMessages(actor),
      recentNotifications: notes.take(5).toList(),
    );
  }

  Future<void> _seed() async {
    final existing = await _meta.record('seed').get(_db);
    if (existing != null) return;
    final password = hashPassword(AuthRepository.demoPassword);
    final catalog = buildPatientCatalog(DateTime.now());
    for (final patient in catalog) {
      final saved = patient.id == 123
          ? patient.copyWith(
              attendingDoctor: 'Anil Mehta',
              medicalHistory: 'Admitted for fever and weakness.',
              allergies: 'None recorded',
              medications: 'Paracetamol',
              email: 'patient@cityhospital.org',
              phone: '9876543210',
              emergencyContactName: 'Priya Sharma',
              emergencyContactPhone: '9876500000',
            )
          : patient;
      await _patients.record(saved.id).put(_db, saved.toJson());
    }
    final doctors = _seedDoctors();
    for (final doctor in doctors) {
      await _doctors.record(doctor.id).put(_db, doctor.toJson());
    }
    final users = [
      ClinicUser(
        email: 'admin@cityhospital.org',
        name: 'Ananya Shah',
        role: UserRole.admin,
        passwordHash: password,
      ),
      ClinicUser(
        email: AuthRepository.demoEmail,
        name: 'Anil Mehta',
        role: UserRole.doctor,
        passwordHash: password,
        doctorId: anilId,
      ),
      ClinicUser(
        email: 'patient@cityhospital.org',
        name: 'Rahul Sharma',
        role: UserRole.patient,
        passwordHash: password,
        patientId: 123,
        doctorId: anilId,
      ),
    ];
    for (final user in users) {
      await _users.record(user.email).put(_db, user.toJson());
    }
    final now = DateTime.now();
    for (final patientId in [123, 124, 125]) {
      await _putRel(
        PatientDoctorRelationship(
          id: 'rel-seed-$patientId',
          patientId: patientId,
          doctorId: anilId,
          status: RelationshipStatus.active,
          assignedAt: now,
          updatedAt: now,
        ),
      );
    }
    await _meta.record('seed').put(_db, {'version': 1});
  }

  List<Doctor> _seedDoctors() {
    return const [
      Doctor(
        id: anilId,
        name: 'Anil Mehta',
        email: AuthRepository.demoEmail,
        phone: '9811111111',
        specialization: 'General Medicine',
        qualification: 'MBBS, MD',
        yearsExperience: 18,
        hospital: 'City Hospital',
        consultationFee: 800,
        availableDays: ['Mon', 'Wed', 'Fri'],
        timeSlots: ['Morning', 'Afternoon'],
        bio: 'Looks after the general medicine ward.',
      ),
      Doctor(
        id: 'D-1002',
        name: 'Neha Kulkarni',
        email: 'neha.kulkarni@cityhospital.org',
        phone: '9822222222',
        specialization: 'Cardiology',
        qualification: 'MBBS, DM Cardiology',
        yearsExperience: 12,
        hospital: 'City Hospital',
        consultationFee: 1200,
        availableDays: ['Tue', 'Thu'],
        timeSlots: ['Morning'],
        bio: 'Cardiology consultations and follow-up.',
      ),
      Doctor(
        id: 'D-1003',
        name: 'Farhan Qureshi',
        email: 'farhan.qureshi@cityhospital.org',
        phone: '9833333333',
        specialization: 'Intensive Care',
        qualification: 'MBBS, MD Critical Care',
        yearsExperience: 15,
        hospital: 'City Hospital',
        consultationFee: 1500,
        availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        timeSlots: ['Morning', 'Evening'],
        bio: 'Covers the intensive care unit.',
      ),
      Doctor(
        id: 'D-1004',
        name: 'Leela Iyer',
        email: 'leela.iyer@cityhospital.org',
        phone: '9844444444',
        specialization: 'Neurology',
        qualification: 'MBBS, DM Neurology',
        yearsExperience: 9,
        hospital: 'City Hospital',
        consultationFee: 1100,
        availableDays: ['Wed', 'Sat'],
        timeSlots: ['Afternoon'],
        bio: 'Neurology reviews for admitted patients.',
      ),
    ];
  }

  Future<List<Patient>> _visiblePatients(Actor actor) async {
    final all = await _allPatients();
    if (actor.isAdmin) return all;
    if (actor.role == UserRole.patient) {
      return all.where((patient) => patient.id == actor.patientId).toList();
    }
    final ids = (await _allRels())
        .where(
          (rel) =>
              rel.doctorId == actor.doctorId &&
              rel.status == RelationshipStatus.active,
        )
        .map((rel) => rel.patientId)
        .toSet();
    return all.where((patient) => ids.contains(patient.id)).toList();
  }

  Future<List<PatientDoctorRelationship>> _visibleRels(Actor actor) async {
    final all = await _allRels();
    if (actor.isAdmin) return all;
    if (actor.role == UserRole.patient) {
      return all.where((rel) => rel.patientId == actor.patientId).toList();
    }
    return all.where((rel) => rel.doctorId == actor.doctorId).toList();
  }

  Future<bool> _doctorAssigned(Actor actor, int patientId) async {
    if (actor.role != UserRole.doctor) return false;
    final rels = await _relsForPatient(patientId);
    return rels.any(
      (rel) =>
          rel.doctorId == actor.doctorId &&
          rel.status == RelationshipStatus.active,
    );
  }

  Future<Set<String>> _activeDoctorIdsForPatient(int? patientId) async {
    if (patientId == null) return {};
    final rels = await _relsForPatient(patientId);
    return rels
        .where((rel) => rel.status == RelationshipStatus.active)
        .map((rel) => rel.doctorId)
        .toSet();
  }

  Future<Patient> _patientOrThrow(int id) async {
    final patient = await _findPatient(id);
    if (patient == null) throw PatientNotFoundException(id);
    return patient;
  }

  Future<Patient?> _findPatient(int id) async {
    final raw = await _patients.record(id).get(_db);
    if (raw == null) return null;
    return Patient.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<Patient>> _allPatients() async {
    final records = await _patients.find(_db);
    return records
        .map(
          (record) => Patient.fromJson(Map<String, dynamic>.from(record.value)),
        )
        .toList();
  }

  Future<Doctor> _doctorOrThrow(String id) async {
    final raw = await _doctors.record(id).get(_db);
    if (raw == null) throw ClinicException('Doctor $id was not found.');
    return Doctor.fromJson(raw);
  }

  Future<List<Doctor>> _allDoctors() async {
    final records = await _doctors.find(_db);
    return records.map((record) => Doctor.fromJson(record.value)).toList();
  }

  Future<List<PatientDoctorRelationship>> _allRels() async {
    final records = await _rels.find(_db);
    return records
        .map((record) => PatientDoctorRelationship.fromJson(record.value))
        .toList();
  }

  Future<List<PatientDoctorRelationship>> _relsForPatient(int patientId) async {
    final records = await _rels.find(
      _db,
      finder: Finder(filter: Filter.equals('patient_id', patientId)),
    );
    return records
        .map((record) => PatientDoctorRelationship.fromJson(record.value))
        .toList();
  }

  Future<List<Appointment>> _allAppointments() async {
    final records = await _appointments.find(_db);
    final items = records
        .map((record) => Appointment.fromJson(record.value))
        .toList();
    items.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return items;
  }

  Future<List<Appointment>> _appointmentsForPatient(int patientId) async {
    final records = await _appointments.find(
      _db,
      finder: Finder(filter: Filter.equals('patient_id', patientId)),
    );
    return records.map((record) => Appointment.fromJson(record.value)).toList();
  }

  Future<Appointment> _appointmentOrThrow(String id) async {
    final raw = await _appointments.record(id).get(_db);
    if (raw == null) throw ClinicException('Consultation was not found.');
    return Appointment.fromJson(raw);
  }

  Future<Conversation> _requireConversation(
    Actor actor,
    String conversationId,
  ) async {
    final raw = await _conversations.record(conversationId).get(_db);
    if (raw == null) throw ClinicException('This conversation does not exist.');
    final conversation = Conversation.fromJson(raw);
    _policy.readConversation(
      actor,
      patientEmail: conversation.patientEmail,
      doctorEmail: conversation.doctorEmail,
    );
    return conversation;
  }

  Future<List<ChatMessage>> _messagesFor(String conversationId) async {
    final records = await _messages.find(
      _db,
      finder: Finder(filter: Filter.equals('conversation_id', conversationId)),
    );
    final items = records
        .map((record) => ChatMessage.fromJson(record.value))
        .toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Future<List<ClinicNotification>> _notesFor(String email) async {
    final records = await _notes.find(
      _db,
      finder: Finder(filter: Filter.equals('user_email', email.toLowerCase())),
    );
    final items = records
        .map((record) => ClinicNotification.fromJson(record.value))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<ClinicUser?> _userForPatient(int patientId) async {
    final records = await _users.find(
      _db,
      finder: Finder(filter: Filter.equals('patient_id', patientId)),
    );
    if (records.isEmpty) return null;
    return ClinicUser.fromJson(records.first.value);
  }

  Future<void> _pointPatientUser(int patientId, String doctorId) async {
    final records = await _users.find(
      _db,
      finder: Finder(filter: Filter.equals('patient_id', patientId)),
    );
    for (final record in records) {
      final user = ClinicUser.fromJson(record.value);
      await _users
          .record(user.email)
          .put(
            _db,
            ClinicUser(
              email: user.email,
              name: user.name,
              role: user.role,
              passwordHash: user.passwordHash,
              patientId: user.patientId,
              doctorId: doctorId,
            ).toJson(),
          );
    }
  }

  Future<void> _notify({
    required String email,
    required String title,
    required String message,
    required String route,
  }) async {
    final target = email.trim().toLowerCase();
    if (target.isEmpty) return;
    final note = ClinicNotification(
      id: _id('n'),
      userEmail: target,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      route: route,
    );
    await _notes.record(note.id).put(_db, note.toJson());
    _bus.publish('notify:$target');
  }

  Future<void> _putRel(PatientDoctorRelationship rel) {
    return _rels.record(rel.id).put(_db, rel.toJson());
  }

  Future<void> _putAppointment(Appointment appointment) {
    return _appointments.record(appointment.id).put(_db, appointment.toJson());
  }

  PatientDoctorRelationship _inactive(
    PatientDoctorRelationship rel,
    DateTime now,
  ) {
    return PatientDoctorRelationship(
      id: rel.id,
      patientId: rel.patientId,
      doctorId: rel.doctorId,
      status: RelationshipStatus.inactive,
      assignedAt: rel.assignedAt,
      updatedAt: now,
    );
  }

  Appointment _appointmentWith(
    Appointment appointment,
    AppointmentStatus status,
    DateTime now,
  ) {
    return Appointment(
      id: appointment.id,
      patientId: appointment.patientId,
      doctorId: appointment.doctorId,
      status: status,
      scheduledAt: appointment.scheduledAt,
      reason: appointment.reason,
      createdAt: appointment.createdAt,
      updatedAt: now,
    );
  }

  String _id(String prefix) {
    _sequence += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_sequence';
  }

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static const _adminEmail = 'admin@cityhospital.org';
}
