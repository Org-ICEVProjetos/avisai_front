import 'dart:io';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Obtém a localização atual do usuário
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se os serviços de localização estão habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw PlatformException(
        code: 'LOCATION_SERVICES_DISABLED',
        message: 'Os serviços de localização estão desabilitados.',
      );
    }

    // Verifica permissões
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw PlatformException(
          code: 'LOCATION_PERMISSION_DENIED',
          message: 'As permissões de localização foram negadas.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw PlatformException(
        code: 'LOCATION_PERMISSION_PERMANENTLY_DENIED',
        message:
            'As permissões de localização foram negadas permanentemente. Não é possível solicitar permissões.',
      );
    }

    // Obtém a localização atual
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Calcula a distância entre duas coordenadas
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Fórmula de Haversine para calcular distância entre coordenadas
    var earthRadius = 6371000; // metros
    var dLat = _degreesToRadians(endLatitude - startLatitude);
    var dLon = _degreesToRadians(endLongitude - startLongitude);
    var a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(startLatitude)) *
            math.cos(_degreesToRadians(endLatitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    var distance = earthRadius * c;
    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // Obtém dados do endereço a partir da localização
  Future<Map<String, String>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Primeiro tenta usar a API do Google Maps
      return await _getAddressFromOpenStreetMap(latitude, longitude);
    } catch (e) {
      // Se falhar, usar o geocoding local
      return await _getAddressFromGeocoding(latitude, longitude);
    }
  }

  Future<Map<String, String>> _getAddressFromOpenStreetMap(
    double latitude,
    double longitude,
  ) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Avisai/1.0', // Importante para a API Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extrair componentes do endereço
        final addressComponents = data['address'] as Map<String, dynamic>;

        // Endereço completo
        final endereco = data['display_name'] ?? 'Não disponível';

        // Componentes individuais
        final rua =
            addressComponents['road'] ??
            addressComponents['pedestrian'] ??
            addressComponents['footway'] ??
            'Não disponível';

        final bairro =
            addressComponents['suburb'] ??
            addressComponents['neighbourhood'] ??
            addressComponents['district'] ??
            'Não disponível';

        final cidade =
            addressComponents['city'] ??
            addressComponents['town'] ??
            addressComponents['village'] ??
            'Não disponível';

        return {
          'endereco': endereco,
          'rua': rua,
          'bairro': bairro,
          'cidade': cidade,
        };
      }

      // Retornar valores padrão em caso de erro
      return {
        'endereco': 'Não disponível',
        'rua': 'Não disponível',
        'bairro': 'Não disponível',
        'cidade': 'Não disponível',
      };
    } catch (e) {
      print('Erro ao obter endereço: $e');
      // Em caso de erro, retornar valores padrão
      return {
        'endereco': 'Não disponível',
        'rua': 'Não disponível',
        'bairro': 'Não disponível',
        'cidade': 'Não disponível',
      };
    }
  }

  Future<Map<String, String>> _getAddressFromGeocoding(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String endereco =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';

        return {
          'endereco': endereco,
          'rua': place.street ?? '',
          'bairro': place.subLocality ?? '',
          'cidade': place.locality ?? '',
        };
      }
    } catch (e) {
      print('Erro ao obter endereço local: $e');
    }

    throw Exception('Não foi possível obter o endereço');
  }

  // Função para analisar uma coordenada GPS de uma string
  double _parseGpsCoordinate(String coord) {
    // Use regex para extrair números do formato "X deg Y' Z" S/N/E/W"
    // ou qualquer outro formato que o EXIF forneça

    try {
      // Tentativa 1: Formato com graus, minutos, segundos
      RegExp degMinSecRegex = RegExp(r"(\d+)\s*deg\s*(\d+)\'\s*(\d+\.?\d*)");
      var match = degMinSecRegex.firstMatch(coord);

      if (match != null) {
        double degrees = double.parse(match.group(1)!);
        double minutes = double.parse(match.group(2)!);
        double seconds = double.parse(match.group(3)!);

        return degrees + (minutes / 60.0) + (seconds / 3600.0);
      }

      // Tentativa 2: Formato decimal simples
      RegExp decimalRegex = RegExp(r'(\d+\.?\d*)');
      match = decimalRegex.firstMatch(coord);

      if (match != null) {
        return double.parse(match.group(1)!);
      }

      // Formato não reconhecido
      print('Formato de coordenada não reconhecido: $coord');
      return 0.0;
    } catch (e) {
      print('Erro ao analisar coordenada: $e');
      return 0.0;
    }
  }
}

// Classe auxiliar para lidar com frações racionais do exif
class Ratio {
  final int numerator;
  final int denominator;

  Ratio(this.numerator, this.denominator);

  double toDouble() {
    if (denominator == 0) return 0.0;
    return numerator / denominator;
  }
}
