import 'package:example/data/data_source/photo_api.dart';
import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fetchPhotos returns 10 photos for a non-empty query', () async {
    final result = await PhotoApi().fetchPhotos(query: 'cat');

    switch (result) {
      case Success(:final data):
        expect(data, hasLength(10));
        expect(data.first.tags, 'cat');
      case Failure():
        fail('expected a Success result');
    }
  });

  test('fetchPhotos fails for an empty query', () async {
    final result = await PhotoApi().fetchPhotos(query: '  ');

    switch (result) {
      case Success():
        fail('expected a Failure result');
      case Failure(:final error):
        expect(error, 'query must not be empty');
    }
  });
}
