# flutter_bloc_kit

*Read this in other languages: [한국어](README.ko.md)*

A [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) extension that provides a `flutter_bloc`-based architecture separating **data / domain / presentation** layers. It mirrors [flutter_provider_kit](https://github.com/cleanwash/flutter_provider_kit) / [flutter_riverpod_kit](https://github.com/cleanwash/flutter_riverpod_kit)'s folder structure, implemented with flutter_bloc.

## What's included

- `Result<T>` — a `Success`/`Failure` sealed class, handled with Dart 3 pattern matching (`switch`)
- `UseCase<Output, Params>` — base class the use cases under `domain/use_case/` extend
- Re-exports the whole `flutter_bloc` package (no need to add it separately)

`Bloc<Event, State>` already separates event and state on its own, so this package doesn't add an extra base class like `MviViewModel` in the provider/riverpod kits.

## Install

```yaml
dependencies:
  flutter_bloc_kit: ^0.0.1
```

## Recommended folder structure

`example/` implements a "photo search" feature end to end (with mock data) using this structure.

```
lib/
  data/
    data_source/
      photo_api.dart              # external API calls (mocked here)
    repository/
      photo_repository_impl.dart  # implements the domain's abstract interface
  domain/
    model/
      photo.dart                  # freezed model
    repository/
      photo_repository.dart       # abstract interface
    use_case/
      get_photos_use_case.dart    # extends UseCase<Output, Params>
  presentation/
    home/
      components/
        photo_widget.dart         # widget local to home
      home_screen.dart            # BlocProvider + BlocConsumer
      home_event.dart             # events sent to the bloc (SearchRequested, ...)
      home_state.dart             # freezed state class (a separate file from the bloc)
      home_bloc.dart              # Bloc<HomeEvent, HomeState>
  di/
    injector.dart                 # manual wiring of repository/use_case/bloc
  main.dart
test/
  data/
    photo_api_test.dart
  ui/
    home_bloc_test.dart
```

### Layer rules

- **domain** is pure business logic with no dependency on Flutter or bloc. `repository/` holds only abstract interfaces; the real implementation lives in `data/repository/`.
- **data** implements `domain`'s interfaces and isolates real API/DB calls inside `data_source/`.
- **presentation** is split into per-feature folders (`home/`, `detail/`, ...), each bundling its own `event`/`state`/`bloc`/`screen`/`components`. `home_state.dart` stays a separate file from `home_bloc.dart`, and freezed generates `==`/`copyWith` for it.
- **di** is currently manual, function-based wiring (`injector.dart`). The structure is kept swappable for `get_it`/`injectable` (already bundled via `flutter_basic_kit_library`) once that's needed — not decided yet.

## Usage

```dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._getPhotosUseCase) : super(const HomeState()) {
    on<SearchRequested>(_onSearchRequested);
  }

  final GetPhotosUseCase _getPhotosUseCase;

  Future<void> _onSearchRequested(SearchRequested event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    switch (await _getPhotosUseCase(event.query)) {
      case Success(:final data):
        emit(state.copyWith(photos: data, isLoading: false));
      case Failure(:final error):
        emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}
```

```dart
// screen
BlocConsumer<HomeBloc, HomeState>(
  listener: (context, state) { /* one-off effects, e.g. a snackbar */ },
  builder: (context, state) { /* UI */ },
)
```

See [`example/`](example) for the full working app.

## Under consideration

- A NestJS-CLI-style code generator for `repository`/`use_case` CRUD boilerplate (not started, to be discussed separately)
- Whether to move DI to `get_it`/`injectable`

## Related packages

| Package | Status |
|---|---|
| [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) | Published |
| [flutter_provider_kit](https://pub.dev/packages/flutter_provider_kit) | Published |
| [flutter_riverpod_kit](https://pub.dev/packages/flutter_riverpod_kit) | Published |
| flutter_bloc_kit | this package |

## Versioning

This package follows [Semantic Versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for the full history.

## Additional information

- Repository: https://github.com/cleanwash/flutter_bloc_kit
- Issues: https://github.com/cleanwash/flutter_bloc_kit/issues
