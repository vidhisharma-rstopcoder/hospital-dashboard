enum UserRole { admin, doctor, patient }

UserRole userRoleFromName(String raw) {
  for (final role in UserRole.values) {
    if (role.name == raw) return role;
  }
  return UserRole.patient;
}

class Actor {
  const Actor({
    required this.role,
    required this.email,
    this.patientId,
    this.doctorId,
  });

  final UserRole role;
  final String email;
  final int? patientId;
  final String? doctorId;

  bool get isAdmin => role == UserRole.admin;
}

class ClinicUser {
  const ClinicUser({
    required this.email,
    required this.name,
    required this.role,
    required this.passwordHash,
    this.patientId,
    this.doctorId,
  });

  final String email;
  final String name;
  final UserRole role;
  final String passwordHash;
  final int? patientId;
  final String? doctorId;

  Map<String, Object?> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'password_hash': passwordHash,
      'patient_id': patientId,
      'doctor_id': doctorId,
    };
  }

  factory ClinicUser.fromJson(Map<String, Object?> json) {
    return ClinicUser(
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: userRoleFromName(json['role'] as String? ?? ''),
      passwordHash: json['password_hash'] as String? ?? '',
      patientId: json['patient_id'] is num
          ? (json['patient_id'] as num).toInt()
          : null,
      doctorId: json['doctor_id'] as String?,
    );
  }
}

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.qualification,
    required this.yearsExperience,
    required this.hospital,
    required this.consultationFee,
    required this.availableDays,
    required this.timeSlots,
    required this.bio,
    this.photoDataUrl = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String qualification;
  final int yearsExperience;
  final String hospital;
  final int consultationFee;
  final List<String> availableDays;
  final List<String> timeSlots;
  final String bio;
  final String photoDataUrl;

  Doctor copyWith({
    String? name,
    String? email,
    String? phone,
    String? specialization,
    String? qualification,
    int? yearsExperience,
    String? hospital,
    int? consultationFee,
    List<String>? availableDays,
    List<String>? timeSlots,
    String? bio,
    String? photoDataUrl,
  }) {
    return Doctor(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      hospital: hospital ?? this.hospital,
      consultationFee: consultationFee ?? this.consultationFee,
      availableDays: availableDays ?? this.availableDays,
      timeSlots: timeSlots ?? this.timeSlots,
      bio: bio ?? this.bio,
      photoDataUrl: photoDataUrl ?? this.photoDataUrl,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'qualification': qualification,
      'years_experience': yearsExperience,
      'hospital': hospital,
      'consultation_fee': consultationFee,
      'available_days': availableDays,
      'time_slots': timeSlots,
      'bio': bio,
      'photo_data_url': photoDataUrl,
    };
  }

  factory Doctor.fromJson(Map<String, Object?> json) {
    return Doctor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      qualification: json['qualification'] as String? ?? '',
      yearsExperience: json['years_experience'] is num
          ? (json['years_experience'] as num).toInt()
          : 0,
      hospital: json['hospital'] as String? ?? '',
      consultationFee: json['consultation_fee'] is num
          ? (json['consultation_fee'] as num).toInt()
          : 0,
      availableDays: _strings(json['available_days']),
      timeSlots: _strings(json['time_slots']),
      bio: json['bio'] as String? ?? '',
      photoDataUrl: json['photo_data_url'] as String? ?? '',
    );
  }
}

enum RelationshipStatus { pending, active, inactive }

class PatientDoctorRelationship {
  const PatientDoctorRelationship({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.status,
    required this.assignedAt,
    required this.updatedAt,
  });

  final String id;
  final int patientId;
  final String doctorId;
  final RelationshipStatus status;
  final DateTime assignedAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'status': status.name,
      'assigned_at': assignedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PatientDoctorRelationship.fromJson(Map<String, Object?> json) {
    return PatientDoctorRelationship(
      id: json['id'] as String? ?? '',
      patientId: (json['patient_id'] as num?)?.toInt() ?? 0,
      doctorId: json['doctor_id'] as String? ?? '',
      status: RelationshipStatus.values.byName(
        json['status'] as String? ?? 'pending',
      ),
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

enum AppointmentStatus { requested, accepted, rejected, cancelled }

class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.status,
    required this.scheduledAt,
    required this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int patientId;
  final String doctorId;
  final AppointmentStatus status;
  final DateTime scheduledAt;
  final String reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'status': status.name,
      'scheduled_at': scheduledAt.toIso8601String(),
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Appointment.fromJson(Map<String, Object?> json) {
    return Appointment(
      id: json['id'] as String? ?? '',
      patientId: (json['patient_id'] as num?)?.toInt() ?? 0,
      doctorId: json['doctor_id'] as String? ?? '',
      status: AppointmentStatus.values.byName(
        json['status'] as String? ?? 'requested',
      ),
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      reason: json['reason'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

enum DeliveryStatus { sent, delivered, read }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.deliveryStatus,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final DeliveryStatus deliveryStatus;
  final DateTime? readAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'delivery_status': deliveryStatus.name,
      'read_at': readAt?.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    final read = json['read_at'] as String?;
    return ChatMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      receiverId: json['receiver_id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      deliveryStatus: DeliveryStatus.values.byName(
        json['delivery_status'] as String? ?? 'sent',
      ),
      readAt: read == null ? null : DateTime.parse(read),
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientEmail,
    required this.doctorEmail,
  });

  final String id;
  final int patientId;
  final String doctorId;
  final String patientEmail;
  final String doctorEmail;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'patient_email': patientEmail,
      'doctor_email': doctorEmail,
    };
  }

  factory Conversation.fromJson(Map<String, Object?> json) {
    return Conversation(
      id: json['id'] as String? ?? '',
      patientId: (json['patient_id'] as num?)?.toInt() ?? 0,
      doctorId: json['doctor_id'] as String? ?? '',
      patientEmail: json['patient_email'] as String? ?? '',
      doctorEmail: json['doctor_email'] as String? ?? '',
    );
  }
}

class ClinicNotification {
  const ClinicNotification({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.route,
    this.readAt,
  });

  final String id;
  final String userEmail;
  final String title;
  final String message;
  final DateTime createdAt;
  final String route;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'user_email': userEmail,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'route': route,
      'read_at': readAt?.toIso8601String(),
    };
  }

  factory ClinicNotification.fromJson(Map<String, Object?> json) {
    final read = json['read_at'] as String?;
    return ClinicNotification(
      id: json['id'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      route: json['route'] as String? ?? '/dashboard',
      readAt: read == null ? null : DateTime.parse(read),
    );
  }
}

class ClinicSummary {
  const ClinicSummary({
    required this.totalPatients,
    required this.totalDoctors,
    required this.activeRelationships,
    required this.upcomingAppointments,
    required this.pendingRequests,
    required this.unreadMessages,
    required this.recentNotifications,
  });

  final int totalPatients;
  final int totalDoctors;
  final int activeRelationships;
  final int upcomingAppointments;
  final int pendingRequests;
  final int unreadMessages;
  final List<ClinicNotification> recentNotifications;
}

class ClinicAccessException implements Exception {
  ClinicAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ClinicException implements Exception {
  ClinicException(this.message);

  final String message;

  @override
  String toString() => message;
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}
