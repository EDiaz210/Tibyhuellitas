part of 'refuge_bloc.dart';

abstract class RefugeState extends Equatable {
  const RefugeState();

  @override
  List<Object?> get props => [];
}

class RefugeInitial extends RefugeState {
  const RefugeInitial();
}

class RefugeLoading extends RefugeState {
  const RefugeLoading();
}

class RefugeLoaded extends RefugeState {
  final List<Refuge> refuges;

  const RefugeLoaded({required this.refuges});

  @override
  List<Object?> get props => [refuges];
}

class RefugeError extends RefugeState {
  final String message;

  const RefugeError({required this.message});

  @override
  List<Object?> get props => [message];
}
