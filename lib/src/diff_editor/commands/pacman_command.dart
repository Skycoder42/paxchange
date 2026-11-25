import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../pacman/pacman.dart';
import '../prompter.dart';
import 'prompt_command.dart';

abstract base class const PacmanCommand(
  super.console,
  @protected final Pacman pacman,
  final Prompter _prompter,
  super.packageName,
) extends PromptCommand {
  @override
  @nonVirtual
  Future<PromptResult> call() async {
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

final class const InstallCommand(
  super.console,
  super.pacman,
  super._prompter,
  super.packageName,
) extends PacmanCommand {
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

final class const RemoveCommand(
  super.console,
  super.pacman,
  super._prompter,
  super.packageName, {
  final bool recursive = false,
}) extends PacmanCommand {
  @override
  String get key => recursive ? 'r' : 'u';

  @override
  String get description => recursive
      ? 'Remove the package and all its unneeded, implicitly installed, '
            'dependencies from this machine'
      : 'Remove the package from this machine';

  @override
  @protected
  String get operation => recursive ? 'uninstall recursively' : 'uninstall';

  @override
  @protected
  Future<int> runPacman(String packageName) =>
      super.pacman.removePackage(packageName, recursive: recursive);
}

final class const MarkImplicitlyInstalledCommand(
  super.console,
  super.pacman,
  super._prompter,
  super.packageName,
) extends PacmanCommand {
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

final class const MarkExplicitlyInstalledCommand(
  super.console,
  super.pacman,
  super._prompter,
  super.packageName,
) extends PacmanCommand {
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
