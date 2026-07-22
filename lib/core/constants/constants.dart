class AppConstants {
  const AppConstants._();

  static const String appName = 'Suraksha Nepal';
  static const String appVersion = '1.0.0';

  // Google Maps & Location Services API Key
  static const String googleMapsApiKey =
      'AIzaSyDenKkvB6nnbJrd3xqqL8XYmGCltha-UR8';

  // Gemini AI configurations
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
