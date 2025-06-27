class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String openStreetApi = String.fromEnvironment(
    'OPEN_STREET_API',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const int requestTimeout = int.fromEnvironment(
    'REQUEST_TIMEOUT',
    defaultValue: 30,
  );

  static String get apiBaseUrl {
    return baseUrl;
  }
}
