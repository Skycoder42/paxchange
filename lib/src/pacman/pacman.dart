import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../config.dart';
import '../util/process_wrapper.dart';
import 'package_info.dart';

// coverage:ignore-start
final pacmanProvider = Provider(
  (ref) => Pacman(
    ref.watch(processProvider),
    ref.watch(configProvider).queryPackagesTool,
  ),
);
// coverage:ignore-end

class Pacman {
  final ProcessWrapper _process;
  final String? _queryPackagesTool;

  Pacman(this._process, this._queryPackagesTool);

  Stream<String> listExplicitlyInstalledPackages() async* {
    final pacmanProc = await _process.start('pacman', const ['-Qqe']);

    final stderrAdded = stderr.addStream(pacmanProc.stderr);
    try {
      yield* pacmanProc.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      final exitCode = await pacmanProc.exitCode;
      if (exitCode != 0) {
        throw Exception('pacman -Qqe failed with exit code: $exitCode');
      }
    } finally {
      // wait for stderr to complete, but do not catch here
      await stderrAdded.catchError(Zone.current.handleUncaughtError);
    }
  }

  Future<LocalPackageInfo> queryInstalledPackage(String packageName) async {
    final pacmanProc = await _process.start(
      _queryPackagesTool ?? 'pacman',
      ['-Qi', packageName],
    );

    final stderrAdded = stderr.addStream(pacmanProc.stderr);
    try {
      final lines = await pacmanProc.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();

      final exitCode = await pacmanProc.exitCode;
      if (exitCode != 0) {
        throw Exception('pacman -Qqe failed with exit code: $exitCode');
      }

      return LocalPackageInfo.parse(lines);
    } finally {
      // wait for stderr to complete, but do not catch here
      await stderrAdded.catchError(Zone.current.handleUncaughtError);
    }
  }

  Future<RemotePackageInfo> queryUninstalledPackage(String packageName) async {
    final pacmanProc = await _process.start(
      _queryPackagesTool ?? 'pacman',
      ['-Si', packageName],
    );

    final stderrAdded = stderr.addStream(pacmanProc.stderr);
    try {
      final lines = await pacmanProc.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();

      final exitCode = await pacmanProc.exitCode;
      if (exitCode != 0) {
        throw Exception('pacman -Qqe failed with exit code: $exitCode');
      }

      return RemotePackageInfo.parse(lines);
    } finally {
      // wait for stderr to complete, but do not catch here
      await stderrAdded.catchError(Zone.current.handleUncaughtError);
    }
  }
}
