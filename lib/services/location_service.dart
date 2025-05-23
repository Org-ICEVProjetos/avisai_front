import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Obtém a localização atual do usuário
  Future<Position> getCurrentLocation() async {
    LocationPermission permission;

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
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        forceLocationManager: true,
      ),
    );
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
}
