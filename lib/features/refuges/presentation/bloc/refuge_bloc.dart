import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/refuge.dart';
import '../../domain/usecases/refuge_usecases.dart';

part 'refuge_event.dart';
part 'refuge_state.dart';

class RefugeBloc extends Bloc<RefugeEvent, RefugeState> {
  final GetAllRefuges getAllRefuges;
  final GetNearbyRefuges getNearbyRefuges;

  RefugeBloc({
    required this.getAllRefuges,
    required this.getNearbyRefuges,
  }) : super(const RefugeInitial()) {
    on<FetchAllRefuges>(_onFetchAllRefuges);
    on<FetchNearbyRefuges>(_onFetchNearbyRefuges);
  }

  Future<void> _onFetchAllRefuges(
    FetchAllRefuges event,
    Emitter<RefugeState> emit,
  ) async {
    emit(const RefugeLoading());
    final result = await getAllRefuges(NoParams());

    result.fold(
      (failure) => emit(RefugeError(message: failure.message)),
      (refuges) => emit(RefugeLoaded(refuges: refuges)),
    );
  }

  Future<void> _onFetchNearbyRefuges(
    FetchNearbyRefuges event,
    Emitter<RefugeState> emit,
  ) async {
    emit(const RefugeLoading());
    final result = await getNearbyRefuges(
      GetNearbyRefugesParams(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusInKm: event.radiusInKm,
      ),
    );

    result.fold(
      (failure) => emit(RefugeError(message: failure.message)),
      (refuges) => emit(RefugeLoaded(refuges: refuges)),
    );
  }
}
