import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../pacman/pacman.dart';
import 'prompt_command.dart';

enum _PrintTarget {
  local,
  remote,
}

class PrintCommand extends PromptCommand {
  final Pacman _pacman;

  final _PrintTarget _printTarget;

  const PrintCommand.local(this._pacman) : _printTarget = _PrintTarget.local;

  const PrintCommand.remote(this._pacman) : _printTarget = _PrintTarget.remote;

  @visibleForTesting
  int get targetIndex => _printTarget.index;

  @override
  String get key => 'p';

  @override
  String get description => 'Print information about the package';

  @override
  Future<PromptResult> call(Console console, String packageName) async {
    Stream<String> packageStream;
    switch (_printTarget) {
      case _PrintTarget.local:
        packageStream = _pacman.queryInstalledPackage(packageName);
        break;
      case _PrintTarget.remote:
        packageStream = _pacman.queryUninstalledPackage(packageName);
        break;
    }

    console.clearScreen();
    await packageStream.forEach(console.writeLine);
    console.writeLine();

    return PromptResult.repeat;
  }
}
