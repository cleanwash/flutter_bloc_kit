import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';

import '../../domain/model/photo.dart';
import '../../domain/repository/photo_repository.dart';
import '../data_source/photo_api.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl(this._api);

  final PhotoApi _api;

  @override
  Future<Result<List<Photo>>> getPhotos({required String query}) {
    return _api.fetchPhotos(query: query);
  }
}
