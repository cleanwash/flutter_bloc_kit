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
  flutter_bloc_kit: ^0.0.4
```

> ⚠️ **Installing is not enough — you must run `init`.** `flutter pub get` only downloads this package; it does **not** create any folders or add the architecture libraries. `pub get` has no auto-run hook (unlike npm's `postinstall`), so scaffolding is a deliberate, one-time command (next section). Run it once and both the folder structure **and** the dependency stack land in your project.

## Scaffold the structure — run this once (required)

`init` does two things in a single command: **(1)** generates the recommended folders plus a minimal, **ready-to-run `home` feature**, and **(2)** adds the architecture libraries to your `pubspec.yaml`.

```bash
# With the package added as a dependency:
dart run flutter_bloc_kit:init          # creates presentation/home/
dart run flutter_bloc_kit:init login    # feature name as an argument (presentation/login/)

# Or activate the command globally and run it from any project:
dart pub global activate flutter_bloc_kit
bloc_kit init
```

**1. Folders + files it generates**

- `data/data_source`, `data/repository`, `domain/model`, `domain/repository`, `domain/use_case` — empty layer folders
- `presentation/<feature>/` — minimal `state` / `event` / `bloc` / `screen` stubs
- `di/injector.dart` — a manual `build<Feature>Bloc()`
- `core/routing/route_paths.dart` + `core/routing/router.dart` — a `go_router` config routing `RoutePaths.<feature>` to `<Feature>Screen`

**2. Libraries it adds — mirrored from flutter_basic_kit_library**

`init` reads [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library)'s own `pubspec.yaml` at runtime and adds the **same** runtime + dev stack to your app, so the generated architecture works out of the box: routing (`go_router`), DI (`get_it`, `injectable`), networking (`dio`, `retrofit`), model codegen (`freezed`, `json_serializable`, `build_runner`), plus `google_fonts`, `intl`, `flutter_secure_storage`, and more. Because it reads that package directly, the list is a **single source of truth** — when flutter_basic_kit_library adds or bumps a library, `init` picks it up with no change here. `flutter_bloc` is already bundled (re-exported) and provides `BlocProvider`, so no `provider` dependency is needed.

> The folder structure is identical to `flutter_provider_kit`/`flutter_riverpod_kit`; only the contents of `presentation/` (bloc vs view_model) differ by state-management choice. Existing files are never overwritten, so re-running is safe.

After running `init`, verify the setup once:

```bash
flutter pub get
flutter analyze
dart run build_runner build --delete-conflicting-outputs   # if you use the codegen models
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
