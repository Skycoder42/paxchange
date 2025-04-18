import 'package:dart_console/dart_console.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../pacman/pacman.dart';
import '../../providers/console_provider.dart';
import '../../storage/package_file_hierarchy.dart';
import '../commands/pacman_command.dart';
import '../commands/print_command.dart';
import '../commands/prompt_command.dart';
import '../prompter.dart';
import 'command_editor.dart';

part 'cleanup_editor.g.dart';

// coverage:ignore-start
@riverpod
CleanupEditor cleanupEditor(Ref ref, {required bool includeOptional}) =>
    CleanupEditor(
      ref.watch(consoleProvider),
      ref.watch(prompterProvider),
      ref.watch(pacmanProvider),
      includeOptional: includeOptional,
    );
// coverage:ignore-end

class CleanupEditor extends CommandEditor<String> {
  final Pacman _pacman;

  final bool includeOptional;

  CleanupEditor(
    super.console,
    super.prompter,
    this._pacman, {
    required this.includeOptional,
  });

  @override
  Stream<String> loadTargets(
    String machineName,
    PackageFileHierarchy hierarchy,
  ) => _pacman.listUnusedPackages(includeOptional: includeOptional);

  @override
  Stream<PromptCommand> buildCommands(
    String machineName,
    PackageFileHierarchy hierarchy,
    String target,
  ) async* {
    super.prompter.writeTitle(
      message:
          'Found implicitly installed package **$target** '
          'that is not required by any other package!',
      color: ConsoleColor.yellow,
    );

    yield PrintCommand.local(super.console, _pacman, target);
    yield MarkExplicitlyInstalledCommand(
      super.console,
      _pacman,
      super.prompter,
      target,
    );
    yield RemoveCommand(super.console, _pacman, super.prompter, target);
  }
}
