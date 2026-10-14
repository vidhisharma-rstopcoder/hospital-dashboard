final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _phonePattern = RegExp(r'^[6-9][0-9]{9}$');

String? requiredText(String? value, String label) {
  if (value == null || value.trim().isEmpty) return 'Enter $label.';
  return null;
}

String? personNameRule(String? value, {String label = 'the full name'}) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Enter $label.';
  if (!RegExp(r"^[A-Za-z][A-Za-z .'\-]{1,}$").hasMatch(name)) {
    return 'Use letters only, at least 2 characters.';
  }
  return null;
}

String? emailRule(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter an email address.';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
  return null;
}

String? phoneRule(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Enter a phone number.';
  if (!_phonePattern.hasMatch(digits)) {
    return 'Use a 10-digit mobile number.';
  }
  return null;
}

String? dateOfBirthRule(DateTime? value, {DateTime? today}) {
  if (value == null) return 'Choose a date of birth.';
  final now = today ?? DateTime.now();
  final day = DateTime(value.year, value.month, value.day);
  final todayOnly = DateTime(now.year, now.month, now.day);
  if (day.isAfter(todayOnly)) return 'Date of birth cannot be in the future.';
  return null;
}

String? nonNegativeIntRule(String? value, String label, {int? max}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter $label.';
  if (!RegExp(r'^\d+$').hasMatch(text)) return '$label must be digits only.';
  final parsed = int.tryParse(text);
  if (parsed == null || parsed < 0) return '$label must be a whole number.';
  if (max != null && parsed > max) return '$label cannot be more than $max.';
  return null;
}

String? experienceRule(String? value) {
  return nonNegativeIntRule(value, 'Years of experience', max: 80);
}

String? feeRule(String? value) {
  return nonNegativeIntRule(value, 'Consultation fee', max: 999999);
}

String? passwordRule(String? value, {bool required = true}) {
  final password = value ?? '';
  if (password.isEmpty) {
    return required ? 'Enter a password.' : null;
  }
  if (password.contains(' ')) return 'Password cannot contain spaces.';
  if (password.length < 8) return 'Use at least 8 characters.';
  return null;
}

String? confirmPasswordRule(
  String? value,
  String password, {
  bool required = true,
}) {
  final confirm = value ?? '';
  if (password.isEmpty && confirm.isEmpty && !required) return null;
  if (confirm.isEmpty) return 'Confirm the password.';
  if (confirm != password) return 'Passwords do not match.';
  return null;
}

String? patientFormError({
  required String name,
  required String email,
  required String phone,
  required DateTime? dateOfBirth,
  required String gender,
  required String bloodGroup,
  required String address,
  required String emergencyName,
  required String emergencyPhone,
  String password = '',
  String confirmPassword = '',
  bool passwordRequired = false,
}) {
  return personNameRule(name) ??
      emailRule(email) ??
      phoneRule(phone) ??
      dateOfBirthRule(dateOfBirth) ??
      requiredText(gender, 'a gender') ??
      requiredText(bloodGroup, 'a blood group') ??
      requiredText(address, 'the address') ??
      personNameRule(emergencyName, label: 'an emergency contact') ??
      phoneRule(emergencyPhone) ??
      passwordRule(password, required: passwordRequired) ??
      confirmPasswordRule(
        confirmPassword,
        password,
        required: passwordRequired || password.isNotEmpty,
      );
}

String? doctorFormError({
  required String name,
  required String email,
  required String phone,
  required String specialization,
  required String qualification,
  required String years,
  required String hospital,
  required String fee,
  required List<String> days,
  required List<String> slots,
  String password = '',
  String confirmPassword = '',
  bool passwordRequired = false,
}) {
  return personNameRule(name) ??
      emailRule(email) ??
      phoneRule(phone) ??
      requiredText(specialization, 'a specialization') ??
      requiredText(qualification, 'a qualification') ??
      experienceRule(years) ??
      requiredText(hospital, 'the hospital or clinic') ??
      feeRule(fee) ??
      (days.isEmpty ? 'Choose at least one available day.' : null) ??
      (slots.isEmpty ? 'Choose at least one time slot.' : null) ??
      passwordRule(password, required: passwordRequired) ??
      confirmPasswordRule(
        confirmPassword,
        password,
        required: passwordRequired || password.isNotEmpty,
      );
}
