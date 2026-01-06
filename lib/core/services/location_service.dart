import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../error/exceptions.dart';

class LocationCoordinates {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  LocationCoordinates({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    required this.timestamp,
  });
}

abstract class LocationService {
  Future<bool> requestLocationPermission();
  Future<bool> checkLocationPermission();
  Future<LocationCoordinates> getCurrentLocation();
  Stream<LocationCoordinates> getLocationStream();
  Future<void> stopLocationTracking();
}

class LocationServiceImpl implements LocationService {
  late StreamSubscription<Position>? _positionStream;

  @override
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      throw LocationException(message: 'Failed to request permission: $e');
    }
  }

  @override
  Future<bool> checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      throw LocationException(message: 'Failed to check permission: $e');
    }
  }

  @override
  Future<LocationCoordinates> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw LocationException(message: 'Location permission not granted');
      }

      final position = await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: false,
      );

      return LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        heading: position.heading,
        speed: position.speed,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw LocationException(message: 'Failed to get location: $e');
    }
  }

  @override
  Stream<LocationCoordinates> getLocationStream() async* {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw LocationException(message: 'Location permission not granted');
      }

      yield* Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).map((position) => LocationCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            altitude: position.altitude,
            heading: position.heading,
            speed: position.speed,
            timestamp: DateTime.now(),
          ));
    } catch (e) {
      throw LocationException(message: 'Failed to get location stream: $e');
    }
  }

  @override
  Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
  }
}
