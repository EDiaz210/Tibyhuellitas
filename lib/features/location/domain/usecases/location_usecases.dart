import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/location_service.dart';

abstract class LocationRepository {
  Future<Either<Failure, LocationCoordinates>> getCurrentLocation();
  Stream<Either<Failure, LocationCoordinates>> getLocationStream();
  Future<Either<Failure, bool>> requestLocationPermission();
}

class GetCurrentLocation
    implements UseCase<LocationCoordinates, NoParams> {
  final LocationRepository repository;

  GetCurrentLocation({required this.repository});

  @override
  Future<Either<Failure, LocationCoordinates>> call(NoParams params) async {
    return await repository.getCurrentLocation();
  }
}
