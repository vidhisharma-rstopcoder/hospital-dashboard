String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your work email.';
  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!pattern.hasMatch(email)) return 'Enter a valid email address.';
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Enter your password.';
  if (password.length < 8) return 'Use at least 8 characters.';
  return null;
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({this.latency = const Duration(milliseconds: 700)});

  final Duration latency;

  static const demoEmail = 'doctor@cityhospital.org';
  static const demoPassword = 'Ward1234';

  Future<String> signIn(String email, String password) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final normalized = email.trim().toLowerCase();
    if (normalized == demoEmail && password == demoPassword) {
      return normalized;
    }
    throw AuthException('Email or password is wrong.');
  }
}
