import 'package:shared_preferences/shared_preferences.dart';

const _sessionEmailKey = 'cityhospital.session.email';

Future<String?> readTabSessionEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_sessionEmailKey);
}

Future<void> writeTabSessionEmail(String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_sessionEmailKey, email.trim().toLowerCase());
}

Future<void> clearTabSessionEmail() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_sessionEmailKey);
}
