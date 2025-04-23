import 'dart:io';
import 'dart:math' as math;

import 'package:exif/exif.dart';
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
      return await _getAddressFromGoogleMaps(latitude, longitude);
    } catch (e) {
      // Se falhar, usar o geocoding local
      return await _getAddressFromGeocoding(latitude, longitude);
    }
  }

  Future<Map<String, String>> _getAddressFromGoogleMaps(
    double latitude,
    double longitude,
  ) async {
    const apiKey = ApiConfig.googleMapsApiKey;
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final result = data['results'][0];
        String endereco = result['formatted_address'] ?? '';
        String rua = '';
        String bairro = '';
        String cidade = '';

        // Extrair componentes do endereço
        for (var component in result['address_components']) {
          final types = component['types'];
          if (types.contains('route')) {
            rua = component['long_name'];
          } else if (types.contains('sublocality_level_1') ||
              types.contains('sublocality')) {
            bairro = component['long_name'];
          } else if (types.contains('administrative_area_level_2')) {
            cidade = component['long_name'];
          }
        }

        return {
          'endereco': endereco,
          'rua': rua,
          'bairro': bairro,
          'cidade': cidade,
        };
      }
    }

    throw Exception('Não foi possível obter o endereço da Google Maps API');
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

  Future<Map<String, double>?> getCoordinatesFromImageMetadata(
    String imagePath,
  ) async {
    try {
      // Ler os metadados EXIF da imagem
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final tags = await readExifFromBytes(bytes);

      // Log completo para debug
      print('Tags EXIF encontradas: ${tags.length}');
      tags.forEach((key, value) {
        print('Tag: $key, Valor: ${value.printable}');
      });

      // Verificar especificamente por tags GPS
      final gpsKeys = tags.keys.where((k) => k.startsWith('GPS')).toList();
      print('Tags GPS encontradas: $gpsKeys');

      // Se não houver dados GPS, retornar null
      if (gpsKeys.isEmpty) {
        print('Nenhuma tag GPS encontrada na imagem');
        return null;
      }

      // Tentar obter as tags específicas de que precisamos
      IfdTag? latTag = tags['GPS GPSLatitude'];
      IfdTag? latRefTag = tags['GPS GPSLatitudeRef'];
      IfdTag? longTag = tags['GPS GPSLongitude'];
      IfdTag? longRefTag = tags['GPS GPSLongitudeRef'];

      // Log de disponibilidade
      print('Lat tag: ${latTag != null ? "encontrada" : "não encontrada"}');
      print('Lat ref: ${latRefTag?.printable}');
      print('Long tag: ${longTag != null ? "encontrada" : "não encontrada"}');
      print('Long ref: ${longRefTag?.printable}');

      // Se faltarem tags necessárias, retornar null
      if (latTag == null ||
          latRefTag == null ||
          longTag == null ||
          longRefTag == null) {
        print('Dados GPS incompletos na imagem');
        return null;
      }

      // Extrair e converter valores
      try {
        // Converter coordenadas
        String latRef = latRefTag.printable;
        String longRef = longRefTag.printable;

        // Detalhar os valores para debug
        print('Lat raw: ${latTag.printable}');
        print('Long raw: ${longTag.printable}');

        // Extrair números das strings (formato: "X deg Y' Z" S/N/E/W)
        double latitude = _parseGpsCoordinate(latTag.printable);
        double longitude = _parseGpsCoordinate(longTag.printable);

        // Ajustar direção
        if (latRef == 'S') latitude = -latitude;
        if (longRef == 'W') longitude = -longitude;

        print('Coordenadas extraídas: Lat=$latitude, Long=$longitude');

        return {'latitude': latitude, 'longitude': longitude};
      } catch (e) {
        print('Erro ao converter coordenadas: $e');
        return null;
      }
    } catch (e) {
      print('Erro ao ler metadados da imagem: $e');
      return null;
    }
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
