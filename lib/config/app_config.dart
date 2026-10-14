/// Environment values are supplied at build or run time and stay out of the UI.
///
/// ```bash
/// flutter run -d chrome \
///   --dart-define=USE_MOCK_API=false \
///   --dart-define=API_BASE_URL=https://api.example.com
/// ```
class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.cityhospital.org',
  );

  static const useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  static const simulateApiError = bool.fromEnvironment(
    'SIMULATE_API_ERROR',
    defaultValue: false,
  );
}
