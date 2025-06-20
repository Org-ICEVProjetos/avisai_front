class ApiConfig {
  static const String baseUrl = 'https://avisai.site';

  static const String googleMapsApiKey =
      'AIzaSyDCyRqiRsOnocT0tfPHWZzSVZsA3VjGZps';

  static const String openStreetApi =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const int requestTimeout = 30;

  static String get apiBaseUrl {
    return baseUrl;
  }
}

// class ApiConfig {
//   static const String baseUrl = String.fromEnvironment(
//     'BASE_URL',
//     defaultValue: 'http://localhost:3000',
//   );

//   static const String googleMapsApiKey = String.fromEnvironment(
//     'GOOGLE_MAPS_API_KEY',
//     defaultValue: '',
//   );

//   static const String openStreetApi = String.fromEnvironment(
//     'OPEN_STREET_API',
//     defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//   );

//   static const int requestTimeout = int.fromEnvironment(
//     'REQUEST_TIMEOUT',
//     defaultValue: 30,
//   );

//   static String get apiBaseUrl {
//     return baseUrl;
//   }
// }
