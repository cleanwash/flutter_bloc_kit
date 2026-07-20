import '../data/data_source/photo_api.dart';
import '../data/repository/photo_repository_impl.dart';
import '../domain/repository/photo_repository.dart';
import '../domain/use_case/get_photos_use_case.dart';
import '../presentation/home/home_bloc.dart';

/// Manual wiring for now — swap for `get_it`/`injectable`
/// (already bundled via `flutter_basic_kit_library`) once DI needs grow.
HomeBloc buildHomeBloc() {
  final PhotoRepository repository = PhotoRepositoryImpl(PhotoApi());
  final useCase = GetPhotosUseCase(repository);
  return HomeBloc(useCase);
}
