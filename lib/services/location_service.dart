import 'package:avisai4/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static LocalStorageService? localStorage = LocalStorageService();
  // Méotodo que pega a localização atual para mostrar no mapa
  Future<Position> getCurrentLocation() async {
    LocationPermission permission;
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

    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        forceLocationManager: true,
      ),
    );
  }

  Future<Map<String, String>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    Map<String, String> resultado = {
      'endereco': 'Não disponível',
      'rua': 'Não disponível',
      'bairro': 'Não disponível',
      'cidade': 'Não disponível',
    };

    // Tentar OpenStreetMap primeiro
    try {
      resultado = await _getAddressFromOpenStreetMap(
        latitude,
        longitude,
      ).timeout(Duration(seconds: 10));

      // Validar se obteve dados úteis
      if (resultado['endereco'] != 'Não disponível' &&
          resultado['endereco']!.isNotEmpty) {
        return resultado;
      }
    } catch (e) {
      if (kDebugMode) {
        print('OpenStreetMap falhou: $e');
      }
    }

    // Tentar Geocoding como fallback
    try {
      resultado = await _getAddressFromGeocoding(
        latitude,
        longitude,
      ).timeout(Duration(seconds: 8));

      // Validar se obteve dados úteis
      if (resultado['endereco'] != 'Não disponível' &&
          resultado['endereco']!.isNotEmpty) {
        return resultado;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Geocoding falhou: $e');
      }
    }

    // Se ambos falharam, retornar dados básicos baseados em coordenadas
    return {
      'endereco': 'Coordenadas: $latitude, $longitude',
      'rua': 'Não identificada',
      'bairro': 'Não identificado',
      'cidade': 'Teresina', // assumir Teresina baseado nos dados
    };
  }

  // Obtém endereço pela API do OpenStreetMap
  Future<Map<String, String>> _getAddressFromOpenStreetMap(
    double latitude,
    double longitude,
  ) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Avisai/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final addressComponents = data['address'] as Map<String, dynamic>;

        final endereco = data['display_name'] ?? 'Não disponível';

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

      return {
        'endereco': 'Não disponível',
        'rua': 'Não disponível',
        'bairro': 'Não disponível',
        'cidade': 'Não disponível',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter endereço: $e');
      }

      return {
        'endereco': 'Não disponível',
        'rua': 'Não disponível',
        'bairro': 'Não disponível',
        'cidade': 'Não disponível',
      };
    }
  }

  // Obtém endereço pelo geocoding
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
      if (kDebugMode) {
        print('Erro ao obter endereço local: $e');
      }
    }

    throw Exception('Não foi possível obter o endereço');
  }

  Future<bool> isLocationNearSavedDocument(
    double latitude,
    double longitude,
  ) async {
    try {
      List<LatLng> savedLocations =
          await localStorage!.getAllDocumentsLocations();

      for (LatLng savedLocation in savedLocations) {
        double distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          savedLocation.latitude,
          savedLocation.longitude,
        );

        if (distance <= 10.0) {
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao verificar localização próxima: $e');
      }
      return false;
    }
  }
}
