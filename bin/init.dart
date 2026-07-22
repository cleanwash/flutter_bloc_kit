import 'dart:io';

/// Scaffolds the recommended `flutter_bloc_kit` folder structure into the
/// current project's `lib/`, adds `go_router`, and generates a minimal,
/// ready-to-run feature wired to a router.
///
/// Usage (run from your app's project root):
///
/// ```bash
/// dart run flutter_bloc_kit:init          # creates presentation/home/...
/// dart run flutter_bloc_kit:init login    # creates presentation/login/...
/// ```
///
/// `flutter_bloc` is already bundled (re-exported) by this package — it also
/// provides `BlocProvider`, so no `provider` dependency is needed — and the
/// only extra dependency added is `go_router`. Existing files are never
/// overwritten.
Future<void> main(List<String> args) async {
  final feature = (args.isNotEmpty ? args.first : 'home').trim();
  if (!_isValidFeature(feature)) {
    stderr.writeln(
      "✗ Invalid feature name: '$feature'. Use snake_case letters/digits, "
      "e.g. `dart run flutter_bloc_kit:init home`.",
    );
    exitCode = 64; // EX_USAGE
    return;
  }

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln(
      "✗ No `lib/` directory here. Run this from your Flutter project root.",
    );
    exitCode = 66; // EX_NOINPUT
    return;
  }

  final className = _toPascalCase(feature);
  final camelName = _toCamelCase(feature);

  const emptyLayers = [
    'lib/data/data_source',
    'lib/data/repository',
    'lib/domain/model',
    'lib/domain/repository',
    'lib/domain/use_case',
  ];

  final files = <String, String>{
    for (final dir in emptyLayers) '$dir/.gitkeep': '',
    'lib/presentation/$feature/${feature}_state.dart': _stateStub(className),
    'lib/presentation/$feature/${feature}_event.dart': _eventStub(className),
    'lib/presentation/$feature/${feature}_bloc.dart':
        _blocStub(className, feature),
    'lib/presentation/$feature/${feature}_screen.dart':
        _screenStub(className, feature),
    'lib/di/injector.dart': _diStub(className, feature),
    'lib/core/routing/route_paths.dart': _routePathsStub(camelName),
    'lib/core/routing/router.dart': _routerStub(className, camelName, feature),
  };

  final created = <String>[];
  final skipped = <String>[];

  files.forEach((path, contents) {
    final file = File(path);
    if (file.existsSync()) {
      skipped.add(path);
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
    created.add(path);
  });

  stdout.writeln('flutter_bloc_kit — scaffolding "$feature"\n');
  for (final path in created) {
    stdout.writeln('  + $path');
  }
  for (final path in skipped) {
    stdout.writeln('  · $path (exists, left untouched)');
  }

  await _addDependencies(const ['go_router']);

  stdout.writeln(
    '\n✓ Done. Wire `router` (lib/core/routing/router.dart) into '
    'MaterialApp.router() to see ${className}Screen run.',
  );
}

bool _isValidFeature(String name) =>
    RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);

String _toPascalCase(String snake) => snake
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => part[0].toUpperCase() + part.substring(1))
    .join();

String _toCamelCase(String snake) {
  final pascal = _toPascalCase(snake);
  return pascal.isEmpty ? pascal : pascal[0].toLowerCase() + pascal.substring(1);
}

/// Adds any of [packages] not already present in `pubspec.yaml` via
/// `flutter pub add`. Never throws — on failure it prints manual instructions
/// so the scaffold still succeeds offline.
Future<void> _addDependencies(List<String> packages) async {
  final pubspec = File('pubspec.yaml');
  final contents = pubspec.existsSync() ? pubspec.readAsStringSync() : '';
  final missing = packages
      .where((p) => !RegExp('^\\s+$p:', multiLine: true).hasMatch(contents))
      .toList();

  if (missing.isEmpty) {
    stdout.writeln('\nDependencies already present: ${packages.join(', ')}');
    return;
  }

  stdout.writeln('\nAdding dependencies: ${missing.join(', ')} ...');
  try {
    final result =
        await Process.run('flutter', ['pub', 'add', ...missing], runInShell: true);
    if (result.exitCode == 0) {
      stdout.writeln('  ✓ ${missing.join(', ')} added');
    } else {
      stdout.writeln('  ! `flutter pub add` failed:\n${result.stderr}');
      stdout.writeln('  → Add manually: flutter pub add ${missing.join(' ')}');
    }
  } catch (_) {
    stdout.writeln('  ! Could not run `flutter`.');
    stdout.writeln('  → Add manually: flutter pub add ${missing.join(' ')}');
  }
}

String _stateStub(String c) => '''/// State the $c screen reads on every rebuild.
class ${c}State {
  const ${c}State({this.isLoading = false});

  final bool isLoading;

  ${c}State copyWith({bool? isLoading}) {
    return ${c}State(isLoading: isLoading ?? this.isLoading);
  }
}
''';

String _eventStub(String c) =>
    '''/// Every user-triggered event the $c bloc reacts to.
sealed class ${c}Event {
  const ${c}Event();
}

/// Fired once when the screen first appears. Add more events as needed.
class ${c}Started extends ${c}Event {
  const ${c}Started();
}
''';

String _blocStub(String c, String f) =>
    '''import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';

import '${f}_event.dart';
import '${f}_state.dart';

class ${c}Bloc extends Bloc<${c}Event, ${c}State> {
  ${c}Bloc() : super(const ${c}State()) {
    on<${c}Started>(_onStarted);
  }

  // Inject your use cases here, e.g.:
  // final GetSomethingUseCase _getSomething;
  // ${c}Bloc(this._getSomething) : super(const ${c}State()) { ... }

  Future<void> _onStarted(${c}Started event, Emitter<${c}State> emit) async {
    emit(state.copyWith(isLoading: true));
    // TODO: call a use case, then emit the result.
    emit(state.copyWith(isLoading: false));
  }
}
''';

String _screenStub(String c, String f) => '''import 'package:flutter/material.dart';
import 'package:flutter_bloc_kit/flutter_bloc_kit.dart';

import '../../di/injector.dart';
import '${f}_bloc.dart';
import '${f}_event.dart';
import '${f}_state.dart';

class ${c}Screen extends StatelessWidget {
  const ${c}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<${c}Bloc>(
      create: (_) => build${c}Bloc()..add(const ${c}Started()),
      child: const _${c}View(),
    );
  }
}

class _${c}View extends StatelessWidget {
  const _${c}View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$c')),
      body: BlocBuilder<${c}Bloc, ${c}State>(
        builder: (context, state) {
          return Center(
            child: state.isLoading
                ? const CircularProgressIndicator()
                : const Text('$c screen'),
          );
        },
      ),
    );
  }
}
''';

String _diStub(String c, String f) =>
    '''import '../presentation/$f/${f}_bloc.dart';

/// Manual wiring for now — swap for `get_it`/`injectable`
/// (already bundled via `flutter_basic_kit_library`) once DI needs grow.
${c}Bloc build${c}Bloc() {
  // Build repositories + use cases here, then pass them in.
  return ${c}Bloc();
}
''';

String _routePathsStub(String camel) =>
    '''/// Centralized route paths — reference these instead of raw path strings.
abstract final class RoutePaths {
  const RoutePaths._();

  static const String $camel = '/';
}
''';

String _routerStub(String c, String camel, String f) =>
    '''import 'package:go_router/go_router.dart';

import '../../presentation/$f/${f}_screen.dart';
import 'route_paths.dart';

/// App router. Plug into your app root:
///
/// ```dart
/// MaterialApp.router(routerConfig: router);
/// ```
final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: RoutePaths.$camel,
      builder: (context, state) => const ${c}Screen(),
    ),
  ],
);
''';
