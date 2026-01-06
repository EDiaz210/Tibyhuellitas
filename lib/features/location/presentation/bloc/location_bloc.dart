import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/location_service.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationService locationService;

  LocationBloc({required this.locationService}) : super(const LocationInitial()) {
    on<RequestLocationPermission>(_onRequestPermission);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<StartLocationTracking>(_onStartTracking);
  }

  Future<void> _onRequestPermission(
    RequestLocationPermission event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    try {
      final granted = await locationService.requestLocationPermission();
      if (granted) {
        emit(const PermissionGranted());
      } else {
        emit(const PermissionDenied());
      }
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    try {
      final location = await locationService.getCurrentLocation();
      emit(LocationObtained(location: location));
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }

  Future<void> _onStartTracking(
    StartLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await for (final location in locationService.getLocationStream()) {
        emit(LocationTracking(location: location));
      }
    } catch (e) {
      emit(LocationError(message: e.toString()));
    }
  }
}
