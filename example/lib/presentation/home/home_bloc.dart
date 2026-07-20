import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';

import '../../domain/use_case/get_photos_use_case.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._getPhotosUseCase) : super(const HomeState()) {
    on<SearchRequested>(_onSearchRequested);
  }

  final GetPhotosUseCase _getPhotosUseCase;

  Future<void> _onSearchRequested(
    SearchRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    switch (await _getPhotosUseCase(event.query)) {
      case Success(:final data):
        emit(state.copyWith(photos: data, isLoading: false));
      case Failure(:final error):
        emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}
