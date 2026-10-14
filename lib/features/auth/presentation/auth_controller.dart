import 'package:hospital_dashboard/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const sessionEmailKey = 'cityhospital.session.email';

class AuthState {
  const AuthState({
    required this.ready,
    required this.authenticated,
    this.email,
    this.submitting = false,
    this.errorMessage,
  });

  const AuthState.booting()
    : ready = false,
      authenticated = false,
      email = null,
      submitting = false,
      errorMessage = null;

  factory AuthState.signedOut() {
    return const AuthState(ready: true, authenticated: false);
  }

  factory AuthState.signedIn(String email) {
    return AuthState(ready: true, authenticated: true, email: email);
  }

  final bool ready;
  final bool authenticated;
  final String? email;
  final bool submitting;
  final String? errorMessage;

  AuthState copyWith({
    bool? ready,
    bool? authenticated,
    String? email,
    bool clearEmail = false,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      ready: ready ?? this.ready,
      authenticated: authenticated ?? this.authenticated,
      email: clearEmail ? null : (email ?? this.email),
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  AuthController(this._repository);

  final AuthRepository _repository;

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
      state = email == null || email.isEmpty
          ? AuthState.signedOut()
          : AuthState.signedIn(email);
    } catch (_) {
      if (!ref.mounted) return;
      state = AuthState.signedOut();
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final sessionEmail = await _repository.signIn(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(sessionEmailKey, sessionEmail);
      if (!ref.mounted) return false;
      state = AuthState.signedIn(sessionEmail);
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
  () => AuthController(AuthRepository()),
);
