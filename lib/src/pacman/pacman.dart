import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config.dart';
import '../util/process_wrapper.dart';

part 'pacman.g.dart';

// coverage:ignore-start
@riverpod
Pacman pacman(Ref ref) => Pacman(
  ref.watch(processProvider),
  ref.watch(configProvider).pacmanFrontend,
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

  Stream<String> listPackagesForGroup(
    String groupName, {
    bool ignoreErrors = false,
  }) => _streamPacmanLines([
    '-Sgq',
    groupName,
  ], expectedExitCode: ignoreErrors ? null : 0);

  Stream<String> listInstalledPackagesForGroup(String groupName) =>
      _streamPacmanLines(['-Qgq', groupName]);

  Stream<String> listUnusedPackages({bool includeOptional = false}) =>
      _streamPacmanLines([
        '-Qdq',
        if (includeOptional) '-tt' else '-t',
      ], expectedExitCode: null);

  Future<bool> checkIfPackageIsInstalled(String packageName) async {
    final pacmanProc = await _process.start(
      _pacmanFrontend ?? 'pacman',
      ['-Qqi', packageName],
      environment: {'LANG': 'C.UTF-8'},
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
    bool noConfirm = false,
  }) => _executePacmanInteractive([
    '-S',
    if (onlyNeeded) '--needed',
    if (noConfirm) '--noconfirm',
    ...packageNames,
  ]);

  Future<int> removePackage(String packageName, {bool recursive = false}) =>
      _executePacmanInteractive(['-R', if (recursive) '-s', packageName]);

  Future<int> changePackageInstallReason(
    String packageName,
    InstallReason installReason,
  ) => _executePacmanInteractive(['-D', installReason.flag, packageName]);

  Stream<String> _streamPacmanLines(
    List<String> query, {
    int? expectedExitCode = 0,
  }) async* {
    final pacmanProc = await _process.start(
      _pacmanFrontend ?? 'pacman',
      query,
      environment: {'LANG': 'C.UTF-8'},
    );

    final stderrAdded = stderr.addStream(pacmanProc.stderr);
    try {
      yield* pacmanProc.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      final exitCode = await pacmanProc.exitCode;
      if (expectedExitCode != null && exitCode != expectedExitCode) {
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
