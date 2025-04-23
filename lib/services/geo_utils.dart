import 'dart:math' as math;

class GeoUtils {
  static const double earthRadius = 6371000; // metros

  // Calcular distância entre dois pontos usando a fórmula de Haversine
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Converter graus para radianos
    final lat1 = _degreesToRadians(startLatitude);
    final lon1 = _degreesToRadians(startLongitude);
    final lat2 = _degreesToRadians(endLatitude);
    final lon2 = _degreesToRadians(endLongitude);

    // Fórmula de Haversine
    final latDelta = lat2 - lat1;
    final lonDelta = lon2 - lon1;

    final a = math.pow(math.sin(latDelta / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(lonDelta / 2), 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    // Distância em metros
    return earthRadius * c;
  }

  // Verificar se um ponto está dentro de um raio determinado
  static bool isPointInRadius(
    double centerLatitude,
    double centerLongitude,
    double pointLatitude,
    double pointLongitude,
    double radiusMeters,
  ) {
    final distance = calculateDistance(
      centerLatitude,
      centerLongitude,
      pointLatitude,
      pointLongitude,
    );

    return distance <= radiusMeters;
  }

  // Calcular o ponto central de múltiplos pontos
  static Map<String, double> calculateCenterPoint(
      List<Map<String, double>> points) {
    if (points.isEmpty) {
      return {'latitude': 0, 'longitude': 0};
    }

    if (points.length == 1) {
      return points.first;
    }

    double sumX = 0;
    double sumY = 0;
    double sumZ = 0;

    // Converter para coordenadas cartesianas
    for (var point in points) {
      final lat = _degreesToRadians(point['latitude']!);
      final lon = _degreesToRadians(point['longitude']!);

      // Converter para coordenadas cartesianas
      sumX += math.cos(lat) * math.cos(lon);
      sumY += math.cos(lat) * math.sin(lon);
      sumZ += math.sin(lat);
    }

    // Calcular média
    final avgX = sumX / points.length;
    final avgY = sumY / points.length;
    final avgZ = sumZ / points.length;

    // Converter de volta para coordenadas geográficas
    final lon = math.atan2(avgY, avgX);
    final hyp = math.sqrt(avgX * avgX + avgY * avgY);
    final lat = math.atan2(avgZ, hyp);

    return {
      'latitude': _radiansToDegrees(lat),
      'longitude': _radiansToDegrees(lon),
    };
  }

  // Calcular limites (bounds) para um conjunto de pontos
  static Map<String, double> calculateBounds(List<Map<String, double>> points) {
    if (points.isEmpty) {
      return {
        'minLatitude': 0,
        'maxLatitude': 0,
        'minLongitude': 0,
        'maxLongitude': 0,
      };
    }

    double minLat = points.first['latitude']!;
    double maxLat = points.first['latitude']!;
    double minLon = points.first['longitude']!;
    double maxLon = points.first['longitude']!;

    for (var point in points) {
      if (point['latitude']! < minLat) minLat = point['latitude']!;
      if (point['latitude']! > maxLat) maxLat = point['latitude']!;
      if (point['longitude']! < minLon) minLon = point['longitude']!;
      if (point['longitude']! > maxLon) maxLon = point['longitude']!;
    }

    return {
      'minLatitude': minLat,
      'maxLatitude': maxLat,
      'minLongitude': minLon,
      'maxLongitude': maxLon,
    };
  }

  // Calcular um ponto a uma distância e direção de outro
  static Map<String, double> calculateDestinationPoint(
    double startLatitude,
    double startLongitude,
    double distanceMeters,
    double bearingDegrees,
  ) {
    final lat1 = _degreesToRadians(startLatitude);
    final lon1 = _degreesToRadians(startLongitude);
    final bearing = _degreesToRadians(bearingDegrees);

    final angularDistance = distanceMeters / earthRadius;

    // Calcular nova latitude
    final lat2 = math.asin(math.sin(lat1) * math.cos(angularDistance) +
        math.cos(lat1) * math.sin(angularDistance) * math.cos(bearing));

    // Calcular nova longitude
    final lon2 = lon1 +
        math.atan2(
            math.sin(bearing) * math.sin(angularDistance) * math.cos(lat1),
            math.cos(angularDistance) - math.sin(lat1) * math.sin(lat2));

    // Normalizar longitude para -180 a +180
    final normalizedLon = ((lon2 + 3 * math.pi) % (2 * math.pi)) - math.pi;

    return {
      'latitude': _radiansToDegrees(lat2),
      'longitude': _radiansToDegrees(normalizedLon),
    };
  }

  // Calcular o bearing (direção) entre dois pontos
  static double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final lat1 = _degreesToRadians(startLatitude);
    final lon1 = _degreesToRadians(startLongitude);
    final lat2 = _degreesToRadians(endLatitude);
    final lon2 = _degreesToRadians(endLongitude);

    final y = math.sin(lon2 - lon1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);

    final bearing = math.atan2(y, x);

    // Converter para graus e normalizar para 0-360
    return (_radiansToDegrees(bearing) + 360) % 360;
  }

  // Converter graus para radianos
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // Converter radianos para graus
  static double _radiansToDegrees(double radians) {
    return radians * 180 / math.pi;
  }
}
