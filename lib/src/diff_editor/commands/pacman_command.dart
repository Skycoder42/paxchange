import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../pacman/pacman.dart';
import '../prompter.dart';
import 'prompt_command.dart';

abstract base class PacmanCommand extends PromptCommand {
  @protected
  final Pacman pacman;
  final Prompter _prompter;

  const PacmanCommand(super.console, this.pacman, this._prompter);

  @override
  @nonVirtual
  Future<PromptResult> call(String packageName) async {
    console
      ..clearScreen()
      ..setForegroundColor(ConsoleColor.blue)
      ..writeLine('> Running pacman command to $operation $packageName')
      ..resetColorAttributes();
    final exitCode = await runPacman(packageName);
    if (exitCode == 0) {
      return PromptResult.succeeded;
    } else {
      _prompter.writeError(
        'Failed to $operation $packageName! '
        'Package manager failed with exit code $exitCode.',
      );
      return PromptResult.repeat;
    }
  }

  @protected
  String get operation;

  @protected
  Future<int> runPacman(String packageName);
}

final class InstallCommand extends PacmanCommand {
  const InstallCommand(super.console, super.pacman, super._prompter);

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
      super.pacman.installPackages([packageName]);
}

final class RemoveCommand extends PacmanCommand {
  const RemoveCommand(super.console, super.pacman, super._prompter);

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
      super.pacman.removePackage(packageName);
}

final class MarkImplicitlyInstalledCommand extends PacmanCommand {
  const MarkImplicitlyInstalledCommand(
    super.console,
    super.pacman,
    super._prompter,
  );

  @override
  String get key => 'm';

  @override
  String get description => 'Mark the package as installed by a dependency';

  @override
  @protected
  String get operation => 'mark';

  @override
  @protected
  Future<int> runPacman(String packageName) => super.pacman
      .changePackageInstallReason(packageName, InstallReason.asDeps);
}

final class MarkExplicitlyInstalledCommand extends PacmanCommand {
  const MarkExplicitlyInstalledCommand(
    super.console,
    super.pacman,
    super._prompter,
  );

  @override
  String get key => 'm';

  @override
  String get description => 'Mark the package as explicitly installed';

  @override
  @protected
  String get operation => 'mark';

  @override
  @protected
  Future<int> runPacman(String packageName) => super.pacman
      .changePackageInstallReason(packageName, InstallReason.asExplicit);
}
