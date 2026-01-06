import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/pet.dart';
import '../../domain/usecases/pet_usecases.dart';

part 'pet_event.dart';
part 'pet_state.dart';

class PetBloc extends Bloc<PetEvent, PetState> {
  final GetAllPets getAllPets;
  final GetPetById getPetById;
  final SearchPets searchPets;

  PetBloc({
    required this.getAllPets,
    required this.getPetById,
    required this.searchPets,
  }) : super(const PetInitial()) {
    on<FetchAllPets>(_onFetchAllPets);
    on<FetchPetById>(_onFetchPetById);
    on<SearchPetsEvent>(_onSearchPets);
  }

  Future<void> _onFetchAllPets(
    FetchAllPets event,
    Emitter<PetState> emit,
  ) async {
    emit(const PetLoading());
    final result = await getAllPets(NoParams());

    result.fold(
      (failure) => emit(PetError(message: failure.message)),
      (pets) => emit(PetLoaded(pets: pets)),
    );
  }

  Future<void> _onFetchPetById(
    FetchPetById event,
    Emitter<PetState> emit,
  ) async {
    emit(const PetLoading());
    final result = await getPetById(event.petId);

    result.fold(
      (failure) => emit(PetError(message: failure.message)),
      (pet) => emit(PetDetailLoaded(pet: pet)),
    );
  }

  Future<void> _onSearchPets(
    SearchPetsEvent event,
    Emitter<PetState> emit,
  ) async {
    emit(const PetLoading());
    final result = await searchPets(
      SearchPetsParams(
        query: event.query,
        speciesFilter: event.speciesFilter,
        sizeFilter: event.sizeFilter,
      ),
    );

    result.fold(
      (failure) => emit(PetError(message: failure.message)),
      (pets) => emit(PetLoaded(pets: pets)),
    );
  }
}
