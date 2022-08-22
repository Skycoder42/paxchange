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

enum InstallReason {
  asExplicit('--asexplicit'),
  asDeps('--asdeps');

  final String flag;

  const InstallReason(this.flag);
}

class Pacman {
  final ProcessWrapper _process;
  final String? _pacmanFrontend;

  Pacman(this._process, this._pacmanFrontend);

  Stream<String> listExplicitlyInstalledPackages() =>
      _streamPacmanLines(const ['-Qqe']);

  Future<bool> checkIfPackageIsInstalled(String packageName) async {
    final pacmanProc = await _process.start(
      _pacmanFrontend ?? 'pacman',
      ['-Qqi', packageName],
    );
    await pacmanProc.stdout.drain<void>();
    await pacmanProc.stderr.drain<void>();
    return (await pacmanProc.exitCode) == 0;
  }

  Stream<String> queryInstalledPackage(String packageName) =>
      _streamPacmanLines(['-Qi', packageName]);

  Stream<String> queryUninstalledPackage(String packageName) =>
      _streamPacmanLines(['-Si', packageName]);

  Future<int> installPackages(
    List<String> packageNames, {
    bool onlyNeeded = false,
  }) =>
      _executePacmanInteractive([
        '-S',
        if (onlyNeeded) '--needed',
        ...packageNames,
      ]);

  Future<int> removePackage(String packageName) =>
      _executePacmanInteractive(['-R', packageName]);

  Future<int> changePackageInstallReason(
    String packageName,
    InstallReason installReason,
  ) =>
      _executePacmanInteractive(['-D', installReason.flag, packageName]);

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
