import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/model/photo.dart';

part 'home_state.freezed.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    @Default([]) List<Photo> photos,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _HomeState;
}
