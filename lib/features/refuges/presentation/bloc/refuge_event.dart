part of 'refuge_bloc.dart';

abstract class RefugeEvent extends Equatable {
  const RefugeEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllRefuges extends RefugeEvent {
  const FetchAllRefuges();
}

class FetchNearbyRefuges extends RefugeEvent {
  final double latitude;
  final double longitude;
  final double radiusInKm;

  const FetchNearbyRefuges({
    required this.latitude,
    required this.longitude,
    this.radiusInKm = 25.0,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusInKm];
}
