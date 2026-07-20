# flutter_bloc_kit

`flutter_bloc` 기반으로 **data / domain / presentation** 레이어를 분리하는 아키텍처를 제공하는 [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) 확장 패키지입니다. [flutter_provider_kit](https://github.com/cleanwash/flutter_provider_kit) / [flutter_riverpod_kit](https://github.com/cleanwash/flutter_riverpod_kit)과 같은 폴더 구조를 flutter_bloc으로 구현한 버전입니다.

> ⚠️ 아직 pub.dev에 게시되지 않았습니다. 구조 확정 후 게시 예정입니다.

## 포함된 것

- `Result<T>` — `Success`/`Failure` sealed class. Dart 3 패턴 매칭(`switch`)으로 처리
- `UseCase<Output, Params>` — `domain/use_case/`의 유스케이스가 상속하는 기반 클래스
- `flutter_bloc` 패키지 전체를 재export (별도로 추가할 필요 없음)

`Bloc<Event, State>` 자체가 이미 event/state 분리 구조라, provider/riverpod kit의 `BaseViewModel` 같은 별도 기반 클래스는 두지 않았습니다.

## 설치

```yaml
dependencies:
  flutter_bloc_kit: ^0.0.1
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
- pub.dev 게시

## 관련 패키지

| 패키지 | 상태 |
|---|---|
| [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) | 게시됨 |
| [flutter_provider_kit](https://github.com/cleanwash/flutter_provider_kit) | 게시됨 |
| [flutter_riverpod_kit](https://github.com/cleanwash/flutter_riverpod_kit) | 게시됨 |
| flutter_bloc_kit | 미게시 (구조 검토 중) |

## 버전 관리

[Semantic Versioning](https://semver.org/lang/ko/)을 따릅니다. 변경 이력은 [CHANGELOG.md](CHANGELOG.md) 참고.
