import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';

import '../model/photo.dart';
import '../repository/photo_repository.dart';

class GetPhotosUseCase extends UseCase<Result<List<Photo>>, String> {
  GetPhotosUseCase(this._repository);

  final PhotoRepository _repository;

  @override
  Future<Result<List<Photo>>> call(String query) {
    return _repository.getPhotos(query: query);
  }
}
