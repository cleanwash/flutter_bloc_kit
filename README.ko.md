# flutter_bloc_kit

*Read this in other languages: [English](README.md)*

`flutter_bloc` 기반으로 **data / domain / presentation** 레이어를 분리하는 아키텍처를 제공하는 [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) 확장 패키지입니다. [flutter_provider_kit](https://github.com/cleanwash/flutter_provider_kit) / [flutter_riverpod_kit](https://github.com/cleanwash/flutter_riverpod_kit)과 같은 폴더 구조를 flutter_bloc으로 구현한 버전입니다.

## 포함된 것

- `Result<T>` — `Success`/`Failure` sealed class. Dart 3 패턴 매칭(`switch`)으로 처리
- `UseCase<Output, Params>` — `domain/use_case/`의 유스케이스가 상속하는 기반 클래스
- `flutter_bloc` 패키지 전체를 재export (별도로 추가할 필요 없음)

`Bloc<Event, State>` 자체가 이미 event/state 분리 구조라, provider/riverpod kit의 `MviViewModel` 같은 별도 기반 클래스는 두지 않았습니다.

## 설치

```yaml
dependencies:
  flutter_bloc_kit: ^0.0.4
```

> ⚠️ **설치만으로는 부족합니다 — 반드시 `init`을 실행하세요.** `flutter pub get`은 이 패키지를 내려받기만 할 뿐, 폴더를 만들지도 아키텍처 라이브러리를 추가하지도 **않습니다.** `pub get`에는 npm의 `postinstall` 같은 자동 실행 훅이 없어서, scaffold는 아래 명령을 **한 번 직접 실행**해야 합니다. 이 한 번으로 폴더 구조 **와** 라이브러리가 함께 세팅됩니다.

## 폴더 구조 자동 생성 (scaffold) — 최초 1회 필수

`init`은 한 명령으로 두 가지를 합니다: **(1)** 추천 폴더 구조 + **바로 실행되는 최소 `home` 기능** 생성, **(2)** 아키텍처 라이브러리를 `pubspec.yaml`에 추가.

```bash
# 의존성으로 추가한 경우:
dart run flutter_bloc_kit:init          # presentation/home/ 생성
dart run flutter_bloc_kit:init login    # feature명을 인자로 (presentation/login/)

# 또는 전역 명령으로 설치해서 어느 프로젝트에서든 실행:
dart pub global activate flutter_bloc_kit
bloc_kit init
```

**1. 생성되는 폴더 + 파일**

- `data/data_source`, `data/repository`, `domain/model`, `domain/repository`, `domain/use_case` — 빈 레이어 폴더
- `presentation/<feature>/` — `state` / `event` / `bloc` / `screen` 최소 뼈대
- `di/injector.dart` — `build<Feature>Bloc()` 수동 조립
- `core/routing/route_paths.dart` + `core/routing/router.dart` — `RoutePaths.<feature>` → `<Feature>Screen` 으로 라우팅하는 `go_router` 설정

**2. 추가되는 라이브러리 — flutter_basic_kit_library를 참조**

`init`은 실행 시점에 [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library)의 `pubspec.yaml`을 직접 읽어, 그 런타임·dev 스택을 **그대로** 앱에 추가합니다. 그래서 생성된 아키텍처가 바로 동작해요: 라우팅(`go_router`), DI(`get_it`, `injectable`), 네트워킹(`dio`, `retrofit`), 모델 코드젠(`freezed`, `json_serializable`, `build_runner`), 그리고 `google_fonts`, `intl`, `flutter_secure_storage` 등. flutter_basic_kit_library를 직접 읽기 때문에 목록이 **단일 진실 공급원**이 되어, 그 패키지가 라이브러리를 추가/갱신하면 `init`이 자동으로 반영합니다. `flutter_bloc`은 이 패키지가 이미 번들(re-export)하며 `BlocProvider`도 함께 제공하므로 `provider`는 따로 필요 없습니다.

> 폴더 구조는 `flutter_provider_kit`/`flutter_riverpod_kit`과 동일합니다. 상태관리 방식에 따라 `presentation/` 안(bloc vs view_model)만 달라집니다. 이미 있는 파일은 절대 덮어쓰지 않으니 재실행해도 안전합니다.

`init` 실행 후 한 번 확인하세요:

```bash
flutter pub get
flutter analyze
dart run build_runner build --delete-conflicting-outputs   # 코드젠 모델을 쓸 경우
```

## 추천 폴더 구조

`example/`에 아래 구조로 "사진 검색" 기능이 실제로 구현되어 있습니다 (데이터는 mock).

```
lib/
  data/
    data_source/
      photo_api.dart              # 외부 API 호출 (여기서는 mock)
    repository/
      photo_repository_impl.dart  # domain의 abstract interface를 implements
  domain/
    model/
      photo.dart                  # freezed 모델
    repository/
      photo_repository.dart       # abstract interface
    use_case/
      get_photos_use_case.dart    # UseCase<Output, Params> 상속
  presentation/
    home/
      components/
        photo_widget.dart         # home 전용 위젯
      home_screen.dart            # BlocProvider + BlocConsumer
      home_event.dart             # bloc에 보내는 이벤트 (SearchRequested 등)
      home_state.dart             # freezed 상태 클래스 (bloc과 분리된 파일)
      home_bloc.dart              # Bloc<HomeEvent, HomeState>
  di/
    injector.dart                 # repository/use_case/bloc 수동 조립
  main.dart
test/
  data/
    photo_api_test.dart
  ui/
    home_bloc_test.dart
```

### 레이어 규칙

- **domain**은 Flutter/bloc에 의존하지 않는 순수 비즈니스 로직입니다. `repository/`엔 추상 인터페이스만 두고, 실제 구현은 `data/repository/`에서 `implements`합니다.
- **data**는 `domain`의 인터페이스를 구현하고, 실제 API/DB 호출은 `data_source/`에 격리합니다.
- **presentation**은 기능(feature) 단위 폴더(`home/`, `detail/` ...)로 나누고, `event`/`state`/`bloc`/`screen`/`components`를 함께 둡니다. `home_state.dart`는 `home_bloc.dart`와 분리된 파일로, freezed로 `==`/`copyWith`를 자동 생성합니다.
- **di**는 지금은 함수 기반 수동 조립(`injector.dart`)입니다. `flutter_basic_kit_library`에 이미 포함된 `get_it`/`injectable`로 교체할 수 있도록 구조는 그대로 유지됩니다 (아직 확정 아님).

## 사용 예시

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
  listener: (context, state) { /* 스낵바 등 1회성 처리 */ },
  builder: (context, state) { /* UI */ },
)
```

전체 동작은 [`example/`](example)를 참고하세요.

## 앞으로 고려 중인 것

- `repository`/`use_case` CRUD 보일러플레이트를 NestJS CLI 스타일로 자동 생성하는 code generator (미착수, 별도 논의 예정)
- DI를 `get_it`/`injectable`로 전환할지 여부

## 관련 패키지

| 패키지 | 상태 |
|---|---|
| [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) | 게시됨 |
| [flutter_provider_kit](https://pub.dev/packages/flutter_provider_kit) | 게시됨 |
| [flutter_riverpod_kit](https://pub.dev/packages/flutter_riverpod_kit) | 게시됨 |
| flutter_bloc_kit | 이 패키지 |

## 버전 관리

[Semantic Versioning](https://semver.org/lang/ko/)을 따릅니다. 변경 이력은 [CHANGELOG.md](CHANGELOG.md) 참고.

## Additional information

저장소: https://github.com/cleanwash/flutter_bloc_kit
이슈/버그 제보: [GitHub Issues](https://github.com/cleanwash/flutter_bloc_kit/issues)
