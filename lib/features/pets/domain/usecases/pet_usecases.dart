import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/pet.dart';

abstract class PetRepository {
  Future<Either<Failure, List<Pet>>> getAllPets();
  Future<Either<Failure, Pet>> getPetById(String id);
  Future<Either<Failure, List<Pet>>> searchPets({
    required String query,
    String? speciesFilter,
    String? sizeFilter,
  });
  Future<Either<Failure, List<Pet>>> getPetsByRefuge(String refugeId);
  Future<Either<Failure, Pet>> createPet(Pet pet);
  Future<Either<Failure, Pet>> updatePet(Pet pet);
  Future<Either<Failure, void>> deletePet(String petId);
}

class GetAllPets implements UseCase<List<Pet>, NoParams> {
  final PetRepository repository;

  GetAllPets({required this.repository});

  @override
  Future<Either<Failure, List<Pet>>> call(NoParams params) async {
    return await repository.getAllPets();
  }
}

class GetPetById implements UseCase<Pet, String> {
  final PetRepository repository;

  GetPetById({required this.repository});

  @override
  Future<Either<Failure, Pet>> call(String petId) async {
    return await repository.getPetById(petId);
  }
}

class SearchPets implements UseCase<List<Pet>, SearchPetsParams> {
  final PetRepository repository;

  SearchPets({required this.repository});

  @override
  Future<Either<Failure, List<Pet>>> call(SearchPetsParams params) async {
    return await repository.searchPets(
      query: params.query,
      speciesFilter: params.speciesFilter,
      sizeFilter: params.sizeFilter,
    );
  }
}

class SearchPetsParams extends Equatable {
  final String query;
  final String? speciesFilter;
  final String? sizeFilter;

  const SearchPetsParams({
    required this.query,
    this.speciesFilter,
    this.sizeFilter,
  });

  @override
  List<Object?> get props => [query, speciesFilter, sizeFilter];
}
