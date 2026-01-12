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
    print('🏠 RefugeBloc: FetchAllRefuges started');
    emit(const RefugeLoading());
    final result = await getAllRefuges(NoParams());

    result.fold(
      (failure) {
        print('❌ RefugeBloc: Error fetching refuges: ${failure.message}');
        emit(RefugeError(message: failure.message));
      },
      (refuges) {
        print('✅ RefugeBloc: FetchAllRefuges success - ${refuges.length} refuges');
        for (var refuge in refuges) {
          print('   - ${refuge.name}: (${refuge.latitude}, ${refuge.longitude})');
        }
        emit(RefugeLoaded(refuges: refuges));
      },
    );
  }

  Future<void> _onFetchNearbyRefuges(
    FetchNearbyRefuges event,
    Emitter<RefugeState> emit,
  ) async {
    print('🏠 RefugeBloc: FetchNearbyRefuges started (${event.latitude}, ${event.longitude})');
    emit(const RefugeLoading());
    final result = await getNearbyRefuges(
      GetNearbyRefugesParams(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusInKm: event.radiusInKm,
      ),
    );

    result.fold(
      (failure) {
        print('❌ RefugeBloc: Error fetching nearby refuges: ${failure.message}');
        emit(RefugeError(message: failure.message));
      },
      (refuges) {
        print('✅ RefugeBloc: FetchNearbyRefuges success - ${refuges.length} refuges');
        for (var refuge in refuges) {
          print('   - ${refuge.name}: (${refuge.latitude}, ${refuge.longitude})');
        }
        emit(RefugeLoaded(refuges: refuges));
      },
    );
  }
}
