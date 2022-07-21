import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

final pacmanProvider = Provider(
  (ref) => Pacman(),
);

class Pacman {
  Stream<String> listExplicitlyInstalledPackages() async* {
    final pacmanProc = await Process.start('pacman', const ['-Qqe']);

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
}
