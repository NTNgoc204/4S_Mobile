class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://preemotional-ungainly-maryann.ngrok-free.dev',
  );
}
