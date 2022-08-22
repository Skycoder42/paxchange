import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../pacman/pacman.dart';
import '../prompter.dart';
import 'prompt_command.dart';

abstract class PacmanCommand extends PromptCommand {
  @protected
  final Pacman pacman;

  const PacmanCommand(this.pacman);

  @override
  @nonVirtual
  Future<PromptResult> call(Console console, String packageName) async {
    console
      ..clearScreen()
      ..setForegroundColor(ConsoleColor.blue)
      ..writeLine('> Running pacman command to $operation $packageName')
      ..resetColorAttributes();
    final exitCode = await runPacman(packageName);
    if (exitCode == 0) {
      console
        ..writeLine()
        ..writeLine(
          'Successfully ${operation}ed $packageName. '
          'Press any key to continue...',
        )
        ..readKey();
      return PromptResult.succeeded;
    } else {
      Prompter.writeError(
        console,
        'Failed to $operation $packageName! '
        'Package manager failed with exit code $exitCode.',
      );
      return PromptResult.failed;
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
      pacman.installPackages([packageName]);
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

class MarkImplicitlyInstalledCommand extends PacmanCommand {
  const MarkImplicitlyInstalledCommand(super.pacman);

  @override
  String get key => 'm';

  @override
  String get description => 'Mark the package as installed by a dependency';

  @override
  @protected
  String get operation => 'mark';

  @override
  @protected
  Future<int> runPacman(String packageName) =>
      pacman.changePackageInstallReason(packageName, InstallReason.asDeps);
}

class MarkExplicitlyInstalledCommand extends PacmanCommand {
  const MarkExplicitlyInstalledCommand(super.pacman);

  @override
  String get key => 'm';

  @override
  String get description => 'Mark the package as explicitly by a dependency';

  @override
  @protected
  String get operation => 'mark';

  @override
  @protected
  Future<int> runPacman(String packageName) =>
      pacman.changePackageInstallReason(packageName, InstallReason.asExplicit);
}
