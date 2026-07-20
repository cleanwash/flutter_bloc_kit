import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';

import '../../domain/model/photo.dart';

/// Mock stand-in for a real photo REST API (e.g. Pixabay). Swap the body of
/// [fetchPhotos] for a `dio`/`retrofit` call once a real backend is wired up
/// — the rest of the app (repository, use case, bloc) doesn't change.
class PhotoApi {
  Future<Result<List<Photo>>> fetchPhotos({required String query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (query.trim().isEmpty) {
      return const Result.failure('query must not be empty');
    }

    final photos = List.generate(
      10,
      (index) => Photo(
        id: index,
        imageUrl: 'https://picsum.photos/seed/$query$index/400/300',
        tags: query,
      ),
    );
    return Result.success(photos);
  }
}
