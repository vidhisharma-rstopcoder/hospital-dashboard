import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';

class AccessPolicy {
  const AccessPolicy();

  void readPatient(
    Actor actor,
    int patientId, {
    required bool assignedToActor,
  }) {
    if (actor.isAdmin) return;
    if (actor.role == UserRole.patient && actor.patientId == patientId) return;
    if (actor.role == UserRole.doctor && assignedToActor) return;
    throw ClinicAccessException('You cannot open this patient record.');
  }

  void writePatient(
    Actor actor, {
    int? patientId,
    bool assignedToActor = false,
  }) {
    if (actor.isAdmin) return;
    if (patientId != null && actor.role == UserRole.doctor && assignedToActor) {
      return;
    }
    throw ClinicAccessException('You cannot change this patient record.');
  }

  void createPatient(Actor actor) {
    if (actor.isAdmin) return;
    throw ClinicAccessException('Only an admin can register a patient.');
  }

  void deletePatient(Actor actor) {
    if (actor.isAdmin) return;
    throw ClinicAccessException('Only an admin can delete a patient.');
  }

  void readDoctor(Actor actor, {required bool assignedToActor}) {
    if (actor.isAdmin || actor.role == UserRole.doctor) return;
    if (actor.role == UserRole.patient && assignedToActor) return;
    throw ClinicAccessException('You cannot open this doctor profile.');
  }

  void writeDoctor(Actor actor, String doctorId) {
    if (actor.isAdmin) return;
    if (actor.role == UserRole.doctor && actor.doctorId == doctorId) return;
    throw ClinicAccessException('You cannot change this doctor profile.');
  }

  void createDoctor(Actor actor) {
    if (actor.isAdmin) return;
    throw ClinicAccessException('Only an admin can register a doctor.');
  }

  void assignDoctor(Actor actor) {
    if (actor.isAdmin) return;
    throw ClinicAccessException('Only an admin can assign a doctor.');
  }

  void readConversation(
    Actor actor, {
    required String patientEmail,
    required String doctorEmail,
  }) {
    if (actor.isAdmin) return;
    final email = actor.email.toLowerCase();
    if (email == patientEmail.toLowerCase() ||
        email == doctorEmail.toLowerCase()) {
      return;
    }
    throw ClinicAccessException('You are not part of this conversation.');
  }

  void requestConsultation(Actor actor, int patientId) {
    if (actor.isAdmin) return;
    if (actor.role == UserRole.patient && actor.patientId == patientId) return;
    throw ClinicAccessException('You cannot request this consultation.');
  }

  void decideConsultation(Actor actor, {required bool assignedToActor}) {
    if (actor.isAdmin) return;
    if (actor.role == UserRole.doctor && assignedToActor) return;
    throw ClinicAccessException('You cannot update this consultation.');
  }
}
