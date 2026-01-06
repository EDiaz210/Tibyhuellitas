import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/refuge.dart';

abstract class RefugeRepository {
  Future<Either<Failure, List<Refuge>>> getAllRefuges();
  Future<Either<Failure, Refuge>> getRefugeById(String id);
  Future<Either<Failure, List<Refuge>>> getNearbyRefuges({
    required double latitude,
    required double longitude,
    double radiusInKm = 25.0,
  });
  Future<Either<Failure, Refuge>> createRefuge(Refuge refuge);
  Future<Either<Failure, Refuge>> updateRefuge(Refuge refuge);
}

class GetAllRefuges implements UseCase<List<Refuge>, NoParams> {
  final RefugeRepository repository;

  GetAllRefuges({required this.repository});

  @override
  Future<Either<Failure, List<Refuge>>> call(NoParams params) async {
    return await repository.getAllRefuges();
  }
}

class GetNearbyRefuges implements UseCase<List<Refuge>, GetNearbyRefugesParams> {
  final RefugeRepository repository;

  GetNearbyRefuges({required this.repository});

  @override
  Future<Either<Failure, List<Refuge>>> call(
      GetNearbyRefugesParams params) async {
    return await repository.getNearbyRefuges(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusInKm: params.radiusInKm,
    );
  }
}

class GetNearbyRefugesParams extends Equatable {
  final double latitude;
  final double longitude;
  final double radiusInKm;

  const GetNearbyRefugesParams({
    required this.latitude,
    required this.longitude,
    this.radiusInKm = 25.0,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusInKm];
}
