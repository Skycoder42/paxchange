import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../pacman/pacman.dart';
import 'prompt_command.dart';

abstract class PacmanCommand extends PromptCommand {
  @protected
  final Pacman pacman;

  const PacmanCommand(this.pacman);

  @override
  @nonVirtual
  Future<bool> call(Console console, String packageName) async {
    console.clearScreen();
    final exitCode = await runPacman(packageName);
    if (exitCode == 0) {
      console
        ..writeLine()
        ..writeLine(
          'Successfully ${operation}ed $packageName. '
          'Press any key to continue...',
        )
        ..readKey();
      return true;
    } else {
      PromptCommand.writeError(
        console,
        'Failed to $operation $packageName! '
        'Package manager failed with exit code $exitCode.',
      );
      return false;
    }
  }

  @protected
  String get operation;

  @protected
  Future<int> runPacman(String packageName);
}

class InstallCommand extends PacmanCommand {
  const InstallCommand(super.pacman);

  @override
  String get key => 'i';

  @override
  String get description => 'Install the package on this machine';

  @override
  @protected
  String get operation => 'install';

  @override
  @protected
  Future<int> runPacman(String packageName) =>
      pacman.installPackage(packageName);
}

class RemoveCommand extends PacmanCommand {
  const RemoveCommand(super.pacman);

  @override
  String get key => 'r';

  @override
  String get description => 'Remove the package from this machine';

  @override
  @protected
  String get operation => 'uninstall';

  @override
  @protected
  Future<int> runPacman(String packageName) =>
      pacman.removePackage(packageName);
}
