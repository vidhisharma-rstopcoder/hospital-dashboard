import 'package:web/web.dart';

const _sessionEmailKey = 'cityhospital.session.email';

Future<String?> readTabSessionEmail() async {
  final value = window.sessionStorage.getItem(_sessionEmailKey);
  if (value == null || value.isEmpty) return null;
  return value;
}

Future<void> writeTabSessionEmail(String email) async {
  window.sessionStorage.setItem(_sessionEmailKey, email.trim().toLowerCase());
}

Future<void> clearTabSessionEmail() async {
  window.sessionStorage.removeItem(_sessionEmailKey);
}
