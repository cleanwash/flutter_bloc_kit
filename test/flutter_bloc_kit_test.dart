import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class _CounterEvent {}

class _Incremented extends _CounterEvent {}

class _CounterBloc extends Bloc<_CounterEvent, int> {
  _CounterBloc() : super(0) {
    on<_Incremented>((event, emit) => emit(state + 1));
  }
}

class _DoubleUseCase extends UseCase<int, int> {
  @override
  Future<int> call(int params) async => params * 2;
}

void main() {
  test('starts with the initial state', () {
    final bloc = _CounterBloc();
    expect(bloc.state, 0);
    bloc.close();
  });

  test('emits an incremented state for each event', () async {
    final bloc = _CounterBloc();
    bloc.add(_Incremented());
    await expectLater(bloc.stream, emits(1));
    await bloc.close();
  });

  test('Result.success and Result.failure pattern match', () {
    const success = Result<int>.success(1);
    const failure = Result<int>.failure('err');

    expect(switch (success) { Success(:final data) => data, Failure() => -1 }, 1);
    expect(
      switch (failure) { Success() => -1, Failure(:final error) => error },
      'err',
    );
  });

  test('UseCase can be implemented and called', () async {
    final useCase = _DoubleUseCase();
    final result = await useCase(21);
    expect(result, 42);
  });
}
