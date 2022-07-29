import 'dart:async';

import 'package:dart_console/dart_console.dart';

import '../../pacman/pacman.dart';
import 'prompt_command.dart';

enum _PrintTarget {
  local,
  remote,
}

class PrintCommand extends PromptCommand {
  final Pacman pacman;

  final _PrintTarget _printTarget;

  const PrintCommand.local(this.pacman) : _printTarget = _PrintTarget.local;

  const PrintCommand.remote(this.pacman) : _printTarget = _PrintTarget.remote;

  @override
  String get key => 'p';

  @override
  String get description => 'Print information about the package';

  @override
  Future<bool> call(Console console, String packageName) async {
    Stream<String> packageStream;
    switch (_printTarget) {
      case _PrintTarget.local:
        packageStream = pacman.queryInstalledPackage(packageName);
        break;
      case _PrintTarget.remote:
        packageStream = pacman.queryUninstalledPackage(packageName);
        break;
    }

    console.clearScreen();
    await packageStream.forEach(console.writeLine);
    console.writeLine();

    return true;
  }
}
