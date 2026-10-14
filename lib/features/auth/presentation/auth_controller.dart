import 'package:hospital_dashboard/features/auth/data/auth_repository.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const sessionEmailKey = 'cityhospital.session.email';

class AuthState {
  const AuthState({
    required this.ready,
    required this.authenticated,
    this.email,
    this.role = UserRole.doctor,
    this.patientId,
    this.doctorId,
    this.submitting = false,
    this.errorMessage,
  });

  const AuthState.booting()
    : ready = false,
      authenticated = false,
      email = null,
      role = UserRole.doctor,
      patientId = null,
      doctorId = null,
      submitting = false,
      errorMessage = null;

  factory AuthState.signedOut() {
    return const AuthState(ready: true, authenticated: false);
  }

  factory AuthState.signedIn(
    String email, {
    UserRole role = UserRole.doctor,
    int? patientId,
    String? doctorId,
  }) {
    return AuthState(
      ready: true,
      authenticated: true,
      email: email,
      role: role,
      patientId: patientId,
      doctorId: doctorId,
    );
  }

  final bool ready;
  final bool authenticated;
  final String? email;
  final UserRole role;
  final int? patientId;
  final String? doctorId;
  final bool submitting;
  final String? errorMessage;

  Actor get actor {
    return Actor(
      role: role,
      email: email ?? '',
      patientId: patientId,
      doctorId: doctorId,
    );
  }

  AuthState copyWith({
    bool? ready,
    bool? authenticated,
    String? email,
    bool clearEmail = false,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
    UserRole? role,
    int? patientId,
    String? doctorId,
    bool clearLinks = false,
  }) {
    return AuthState(
      ready: ready ?? this.ready,
      authenticated: authenticated ?? this.authenticated,
      email: clearEmail ? null : (email ?? this.email),
      role: role ?? this.role,
      patientId: clearLinks ? null : (patientId ?? this.patientId),
      doctorId: clearLinks ? null : (doctorId ?? this.doctorId),
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthState.booting();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(sessionEmailKey);
      if (!ref.mounted) return;
      if (email == null || email.isEmpty) {
        state = AuthState.signedOut();
        return;
      }
      final store = await ref.read(clinicStoreProvider.future);
      final user = await store.userByEmail(email);
      if (!ref.mounted) return;
      state = user == null
          ? AuthState.signedOut()
          : AuthState.signedIn(
              user.email,
              role: user.role,
              patientId: user.patientId,
              doctorId: user.doctorId,
            );
    } catch (_) {
      if (!ref.mounted) return;
      state = AuthState.signedOut();
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final store = await ref.read(clinicStoreProvider.future);
      final user = await store.authenticate(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(sessionEmailKey, user.email);
      if (!ref.mounted) return false;
      state = AuthState.signedIn(
        user.email,
        role: user.role,
        patientId: user.patientId,
        doctorId: user.doctorId,
      );
      return true;
    } on AuthException catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(submitting: false, errorMessage: error.message);
      return false;
    } catch (_) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        submitting: false,
        errorMessage: 'Sign in failed. Try again in a moment.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionEmailKey);
    if (!ref.mounted) return;
    state = AuthState.signedOut();
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
