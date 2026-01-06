part of 'location_bloc.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationObtained extends LocationState {
  final LocationCoordinates location;

  const LocationObtained({required this.location});

  @override
  List<Object?> get props => [location];
}

class LocationTracking extends LocationState {
  final LocationCoordinates location;

  const LocationTracking({required this.location});

  @override
  List<Object?> get props => [location];
}

class PermissionGranted extends LocationState {
  const PermissionGranted();
}

class PermissionDenied extends LocationState {
  const PermissionDenied();
}

class LocationError extends LocationState {
  final String message;

  const LocationError({required this.message});

  @override
  List<Object?> get props => [message];
}
