import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

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

  // Architecture layers are created as empty directories (no .gitkeep);
  // fill them in per feature (data_source, repository, model, use_case, ...).
  for (final dir in emptyLayers) {
    Directory(dir).createSync(recursive: true);
    created.add('$dir/');
  }

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

  // Read flutter_basic_kit_library's own pubspec and mirror its dependency
  // stack into the consumer app. This keeps the list a single source of truth:
  // updating flutter_basic_kit_library is enough — init needs no changes.
  // flutter_bloc is already bundled via this package.
  await _syncBasicKitDependencies();

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

/// Reads flutter_basic_kit_library's pubspec (resolved as a transitive
/// dependency of this package) and adds the same runtime + dev dependencies to
/// the consumer app. flutter_basic_kit_library is the single source of truth —
/// updating it is automatically reflected here. Falls back to a built-in list
/// if it can't be located (e.g. offline / unusual setups).
Future<void> _syncBasicKitDependencies() async {
  final pubspec = _findBasicKitPubspec();
  Map<String, String> runtime;
  Map<String, String> dev;

  if (pubspec == null) {
    stdout.writeln(
      '\n! Could not locate flutter_basic_kit_library — using built-in list.',
    );
    runtime = _fallbackRuntime;
    dev = _fallbackDev;
  } else {
    final doc = loadYaml(pubspec.readAsStringSync());
    runtime = _extractDeps(doc is YamlMap ? doc['dependencies'] : null);
    dev = _extractDeps(
      doc is YamlMap ? doc['dev_dependencies'] : null,
      denylist: _devDenylist,
    );
    stdout.writeln(
      '\nMirroring flutter_basic_kit_library dependencies '
      '(${runtime.length} runtime, ${dev.length} dev).',
    );
  }

  await _addDependencies(runtime);
  await _addDependencies(dev, dev: true);
}

/// Locates flutter_basic_kit_library's pubspec.yaml through the consumer app's
/// `.dart_tool/package_config.json`. Returns null if it isn't resolved.
File? _findBasicKitPubspec() {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  try {
    final json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
    final packages = json['packages'] as List<dynamic>;
    for (final entry in packages.cast<Map<String, dynamic>>()) {
      if (entry['name'] != 'flutter_basic_kit_library') continue;
      var rootUri = entry['rootUri'] as String;
      if (!rootUri.endsWith('/')) rootUri = '$rootUri/';
      final pubspecUri =
          config.absolute.uri.resolve(rootUri).resolve('pubspec.yaml');
      final pubspec = File.fromUri(pubspecUri);
      return pubspec.existsSync() ? pubspec : null;
    }
  } catch (_) {
    // Malformed config — fall through to the built-in fallback list.
  }
  return null;
}

/// Turns a pubspec `dependencies`/`dev_dependencies` node into a
/// {name: versionConstraint} map, keeping only simple hosted deps (a version
/// string) and dropping sdk/git/path entries plus anything in [denylist].
Map<String, String> _extractDeps(
  Object? node, {
  Set<String> denylist = const {},
}) {
  final deps = <String, String>{};
  if (node is! YamlMap) return deps;
  node.forEach((key, value) {
    final name = key.toString();
    if (denylist.contains(name)) return;
    if (value is String) deps[name] = value;
  });
  return deps;
}

/// Dev tools flutter_basic_kit_library declares that every Flutter app already
/// has — skip them so we don't fight the app's own versions.
const _devDenylist = {'flutter_test', 'flutter_lints'};

/// Used only when flutter_basic_kit_library can't be located. Empty constraint
/// means "let pub pick a compatible version".
const _fallbackRuntime = <String, String>{
  'go_router': '',
  'dio': '',
  'retrofit': '',
  'get_it': '',
  'injectable': '',
  'freezed_annotation': '',
  'json_annotation': '',
  'google_fonts': '',
  'curved_navigation_bar': '',
  'flutter_native_splash': '',
};
const _fallbackDev = <String, String>{
  'build_runner': '',
  'freezed': '',
  'json_serializable': '',
  'injectable_generator': '',
  'retrofit_generator': '',
};

/// Adds any of [deps] (name → version constraint; empty = unpinned) not already
/// present in `pubspec.yaml`. Never throws — on failure it prints manual
/// instructions so the scaffold still succeeds offline.
Future<void> _addDependencies(
  Map<String, String> deps, {
  bool dev = false,
}) async {
  if (deps.isEmpty) return;
  final label = dev ? 'dev dependencies' : 'dependencies';
  final flag = dev ? '--dev ' : '';
  final pubspec = File('pubspec.yaml');
  final contents = pubspec.existsSync() ? pubspec.readAsStringSync() : '';
  final missing = deps.keys
      .where((p) => !RegExp('^\\s+$p:', multiLine: true).hasMatch(contents))
      .toList();

  if (missing.isEmpty) {
    stdout.writeln('\n$label already present: ${deps.keys.join(', ')}');
    return;
  }

  final args = [
    for (final p in missing) (deps[p] ?? '').isEmpty ? p : '$p:${deps[p]}',
  ];
  stdout.writeln('\nAdding $label: ${missing.join(', ')} ...');
  try {
    final result = await Process.run(
      'flutter',
      ['pub', 'add', if (dev) '--dev', ...args],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      stdout.writeln('  ✓ ${missing.join(', ')} added');
    } else {
      stdout.writeln('  ! `flutter pub add` failed:\n${result.stderr}');
      stdout.writeln('  → Add manually: flutter pub add $flag${args.join(' ')}');
    }
  } catch (_) {
    stdout.writeln('  ! Could not run `flutter`.');
    stdout.writeln('  → Add manually: flutter pub add $flag${args.join(' ')}');
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
