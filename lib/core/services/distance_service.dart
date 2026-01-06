import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Servicio para calcular distancias entre ubicaciones
/// usando la fórmula de Haversine
class DistanceService {
  static final DistanceService _instance = DistanceService._internal();

  factory DistanceService() {
    return _instance;
  }

  DistanceService._internal();

  /// Obtiene la ubicación actual del usuario
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permission permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Calcula la distancia entre dos puntos usando la fórmula de Haversine
  /// Retorna la distancia en kilómetros
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;
    final double dLat = _toRad(lat2 - lat1);
    final double dLon = _toRad(lon2 - lon1);
    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Convierte grados a radianes
  double _toRad(double deg) => deg * (pi / 180);

  /// Obtiene la distancia con ubicación actual del usuario
  /// Retorna null si no puede obtener la ubicación
  Future<double?> getDistanceToRefuge(
    double refugeLatitude,
    double refugeLongitude,
  ) async {
    try {
      final userLocation = await getCurrentLocation();
      if (userLocation == null) {
        return null;
      }

      return calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        refugeLatitude,
        refugeLongitude,
      );
    } catch (e) {
      print('❌ Error calculating distance: $e');
      return null;
    }
  }

  /// Formatea la distancia para mostrar en UI
  /// Ejemplo: 2.5 km, 0.8 km, etc.
  String formatDistance(double kilometers) {
    if (kilometers < 1) {
      final meters = (kilometers * 1000).toStringAsFixed(0);
      return '$meters m';
    }
    return '${kilometers.toStringAsFixed(1)} km';
  }
}
