import 'package:intl/intl.dart';

String formatHospitalDate(DateTime date) {
  return DateFormat('d MMM yyyy').format(date);
}

DateTime dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String displayText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Not recorded' : trimmed;
}
