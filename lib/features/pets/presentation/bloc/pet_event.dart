part of 'pet_bloc.dart';

abstract class PetEvent extends Equatable {
  const PetEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllPets extends PetEvent {
  const FetchAllPets();
}

class FetchPetById extends PetEvent {
  final String petId;

  const FetchPetById({required this.petId});

  @override
  List<Object?> get props => [petId];
}

class SearchPetsEvent extends PetEvent {
  final String query;
  final String? speciesFilter;
  final String? sizeFilter;

  const SearchPetsEvent({
    required this.query,
    this.speciesFilter,
    this.sizeFilter,
  });

  @override
  List<Object?> get props => [query, speciesFilter, sizeFilter];
}
