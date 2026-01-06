import 'package:geocoding/geocoding.dart';

abstract class GeocodingService {
  Future<String?> getAddressFromCoordinates(double latitude, double longitude);
  Future<String?> getCityFromCoordinates(double latitude, double longitude);
}

class GeocodingServiceImpl implements GeocodingService {
  @override
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.postalCode} ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  @override
  Future<String?> getCityFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Prioridad: locality > administrativeArea
        return place.locality ?? place.administrativeArea ?? 'Ecuador';
      }
      return 'Ecuador';
    } catch (e) {
      print('Error getting city: $e');
      return 'Ecuador';
    }
  }
}
