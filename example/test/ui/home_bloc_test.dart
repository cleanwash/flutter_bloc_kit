import 'package:example/domain/model/photo.dart';
import 'package:example/domain/repository/photo_repository.dart';
import 'package:example/domain/use_case/get_photos_use_case.dart';
import 'package:example/presentation/home/home_bloc.dart';
import 'package:example/presentation/home/home_event.dart';
import 'package:example/presentation/home/home_state.dart';
import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePhotoRepository implements PhotoRepository {
  _FakePhotoRepository(this.result);
  final Result<List<Photo>> result;

  @override
  Future<Result<List<Photo>>> getPhotos({required String query}) async {
    return result;
  }
}

void main() {
  const photos = [Photo(id: 1, imageUrl: 'url', tags: 'cat')];

  test('emits [loading, success] when search succeeds', () async {
    final bloc = HomeBloc(
      GetPhotosUseCase(_FakePhotoRepository(const Result.success(photos))),
    );
    addTearDown(bloc.close);

    final states = <HomeState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(const SearchRequested('cat'));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await subscription.cancel();

    expect(states, [
      const HomeState(isLoading: true),
      const HomeState(isLoading: false, photos: photos),
    ]);
  });

  test('emits [loading, error] when search fails', () async {
    final bloc = HomeBloc(
      GetPhotosUseCase(_FakePhotoRepository(const Result.failure('network error'))),
    );
    addTearDown(bloc.close);

    final states = <HomeState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(const SearchRequested('cat'));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await subscription.cancel();

    expect(states, [
      const HomeState(isLoading: true),
      const HomeState(isLoading: false, errorMessage: 'network error'),
    ]);
  });
}
