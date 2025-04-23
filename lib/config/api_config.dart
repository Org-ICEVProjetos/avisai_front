class ApiConfig {
  static const String baseUrl = 'https://api.cidadaovigilante.com.br/v1';

  static const String googleMapsApiKey =
      'AIzaSyDCyRqiRsOnocT0tfPHWZzSVZsA3VjGZps';

  static const int requestTimeout = 30;

  static bool get isDevelopment {
    return const bool.fromEnvironment('dart.vm.product') == false;
  }

  static String get devBaseUrl {
    return 'http://localhost:3000/api';
  }

  static String get apiBaseUrl {
    return isDevelopment ? devBaseUrl : baseUrl;
  }
}
