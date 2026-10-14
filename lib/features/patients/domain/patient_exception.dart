class PatientApiException implements Exception {
  PatientApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PatientNotFoundException extends PatientApiException {
  PatientNotFoundException(int id) : super('No patient found for ID $id.');
}
