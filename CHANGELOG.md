## 0.0.6

_(요약: CHANGELOG 비ASCII 비율 정리)_

* Rewrote `CHANGELOG.md` primarily in English, with a short Korean summary line per version, to keep pub.dev's non-ASCII ratio check passing while staying readable in Korean.

## 0.0.5

_(요약: init이 테스트 뼈대도 함께 생성)_

* `init` now also generates test scaffolding: creates `test/presentation/<feature>/<feature>_bloc_test.dart` with an initial-state assertion and an `emitsInOrder` test for the loading on/off state transition (no `bloc_test` dependency needed), plus a guide comment for injecting fakes into the constructor as use cases grow. The consuming app's package name is read automatically from its pubspec.

## 0.0.4

_(요약: basic_kit의 pubspec을 읽어 의존성 자동 미러링)_

* `init` now reads `flutter_basic_kit_library`'s own `pubspec.yaml` directly and mirrors all of its runtime and dev dependencies into the consuming app via `flutter pub add`. The dependency list is no longer hardcoded; `flutter_basic_kit_library` is now the single source of truth, so adding or updating a library there flows through automatically without touching `init` (reflects `flutter_basic_kit_library ^0.0.3`, including `intl` and `flutter_secure_storage`).
* State-management libraries (`provider`/`flutter_bloc`/`flutter_riverpod`) are excluded from mirroring, since each kit already provides its own dependency and re-export, so `provider` no longer gets pulled into bloc apps.
* data/domain layers are now created as empty directories, without `.gitkeep`.
* Added `executables:`, so after `dart pub global activate flutter_bloc_kit` the shorter `bloc_kit init [feature]` command is available.
* Added the `yaml` dependency, used by `init` to parse `flutter_basic_kit_library`'s pubspec.

## 0.0.3

_(요약: init 스캐폴딩 명령 추가)_

* Added the `dart run flutter_bloc_kit:init [feature]` scaffolding command (`bin/init.dart`). Generates data/domain layer folders, a minimal runnable `presentation/<feature>` (state/event/bloc/screen), `di/injector.dart`, and `core/routing/route_paths.dart` + `router.dart` (go_router) scaffolding, without overwriting existing files. Feature name defaults to `home`. Folder structure matches the provider/riverpod kits.
* `init` now automatically runs `flutter pub add` for `go_router`. `flutter_bloc` is already re-exported and provides `BlocProvider`, so `provider` is not added.

## 0.0.2

_(요약: 라이브러리 진입점에 dartdoc 추가)_

* Added a `library;` directive with dartdoc to the library entry point (`lib/flutter_bloc_kit.dart`).

## 0.0.1

_(요약: 초기 구성)_

* Initial configuration: added `Result`, `UseCase`. Configured `flutter_basic_kit_library` and `flutter_bloc` dependencies.
* Structured `example/` into data/domain/presentation/di layers and added a mock-datasource-based photo search (home) feature.
