import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../pacman/pacman.dart';
import 'prompt_command.dart';

@visibleForTesting
enum PrintTarget {
  local,
  remote,
}

class PrintCommand extends PromptCommand {
  final Pacman _pacman;

  @visibleForTesting
  final PrintTarget printTarget;

  const PrintCommand.local(this._pacman) : printTarget = PrintTarget.local;

  const PrintCommand.remote(this._pacman) : printTarget = PrintTarget.remote;

  @override
  String get key => 'p';

  @override
  String get description => 'Print information about the package';

  @override
  Future<PromptResult> call(Console console, String packageName) async {
    Stream<String> packageStream;
    switch (printTarget) {
      case PrintTarget.local:
        packageStream = _pacman.queryInstalledPackage(packageName);
      case PrintTarget.remote:
        packageStream = _pacman.queryUninstalledPackage(packageName);
    }

    console.clearScreen();
    await packageStream.forEach(console.writeLine);
    console.writeLine();

    return PromptResult.repeat;
  }
}
