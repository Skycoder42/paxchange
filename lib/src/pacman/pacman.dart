import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../config.dart';
import '../util/process_wrapper.dart';

// coverage:ignore-start
final pacmanProvider = Provider(
  (ref) => Pacman(
    ref.watch(processProvider),
    ref.watch(configProvider).pacmanFrontend,
  ),
);
// coverage:ignore-end

class Pacman {
  final ProcessWrapper _process;
  final String? _pacmanFrontend;

  Pacman(this._process, this._pacmanFrontend);

  Stream<String> listExplicitlyInstalledPackages() =>
      _streamPacmanLines(const ['-Qqe']);

  Stream<String> queryInstalledPackage(String packageName) =>
      _streamPacmanLines(['-Qi', packageName]);

  Stream<String> queryUninstalledPackage(String packageName) =>
      _streamPacmanLines(['-Si', packageName]);

  Future<int> installPackage(String packageName) =>
      _executePacmanInteractive(['-S', packageName]);

  Future<int> removePackage(String packageName) =>
      _executePacmanInteractive(['-R', packageName]);

  Stream<String> _streamPacmanLines(List<String> query) async* {
    final pacmanProc = await _process.start(
      _pacmanFrontend ?? 'pacman',
      query,
    );

    final stderrAdded = stderr.addStream(pacmanProc.stderr);
    try {
      yield* pacmanProc.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      final exitCode = await pacmanProc.exitCode;
      if (exitCode != 0) {
        throw Exception(
          'pacman ${query.join(' ')} failed with exit code: $exitCode',
        );
      }
    } finally {
      // wait for stderr to complete, but do not catch here
      await stderrAdded.catchError(Zone.current.handleUncaughtError);
    }
  }

  Future<int> _executePacmanInteractive(List<String> command) async {
    final pacmanProc = await _process.start(
      _pacmanFrontend ?? 'pacman',
      command,
      mode: ProcessStartMode.inheritStdio,
    );

    return pacmanProc.exitCode;
  }
}
