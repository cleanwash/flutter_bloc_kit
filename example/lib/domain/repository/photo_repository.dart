import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';

import '../model/photo.dart';

/// Abstract interface implemented by `data/repository/photo_repository_impl.dart`.
abstract interface class PhotoRepository {
  Future<Result<List<Photo>>> getPhotos({required String query});
}
