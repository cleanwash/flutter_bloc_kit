/// Wraps the outcome of an operation (typically a repository/data-source
/// call) as either [Success] or [Failure], for use with Dart 3 pattern
/// matching (`switch`) instead of throwing.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Object error) = Failure<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final Object error;
}
