part of 'pet_bloc.dart';

abstract class PetState extends Equatable {
  const PetState();

  @override
  List<Object?> get props => [];
}

class PetInitial extends PetState {
  const PetInitial();
}

class PetLoading extends PetState {
  const PetLoading();
}

class PetLoaded extends PetState {
  final List<Pet> pets;

  const PetLoaded({required this.pets});

  @override
  List<Object?> get props => [pets];
}

class PetDetailLoaded extends PetState {
  final Pet pet;

  const PetDetailLoaded({required this.pet});

  @override
  List<Object?> get props => [pet];
}

class PetError extends PetState {
  final String message;

  const PetError({required this.message});

  @override
  List<Object?> get props => [message];
}
