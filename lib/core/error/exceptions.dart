/// Custom exceptions for the application
class ServerException implements Exception {
  final String message;
  ServerException({required this.message});
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});
}

class LocationException implements Exception {
  final String message;
  LocationException({required this.message});
}

class AuthException implements Exception {
  final String message;
  AuthException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});
}

class ValidationException implements Exception {
  final String message;
  ValidationException({required this.message});
}
