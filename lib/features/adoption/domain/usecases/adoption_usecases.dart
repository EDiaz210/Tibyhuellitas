import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/adoption_request.dart';

abstract class AdoptionRepository {
  Future<Either<Failure, List<AdoptionRequest>>> getUserRequests(
      String userId);
  Future<Either<Failure, List<AdoptionRequest>>> getRefugeRequests(
      String refugeId);
  Future<Either<Failure, AdoptionRequest>> createRequest(
      AdoptionRequest request);
  Future<Either<Failure, AdoptionRequest>> updateRequestStatus(
    String requestId,
    AdoptionRequestStatus status, {
    String? approvalNotes,
  });
}

class CreateAdoptionRequest
    implements UseCase<AdoptionRequest, AdoptionRequest> {
  final AdoptionRepository repository;

  CreateAdoptionRequest({required this.repository});

  @override
  Future<Either<Failure, AdoptionRequest>> call(
      AdoptionRequest params) async {
    return await repository.createRequest(params);
  }
}

class GetUserAdoptionRequests
    implements UseCase<List<AdoptionRequest>, String> {
  final AdoptionRepository repository;

  GetUserAdoptionRequests({required this.repository});

  @override
  Future<Either<Failure, List<AdoptionRequest>>> call(String userId) async {
    return await repository.getUserRequests(userId);
  }
}
