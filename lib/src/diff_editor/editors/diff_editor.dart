import 'package:dart_console/dart_console.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../diff_entry.dart';
import '../../pacman/pacman.dart';
import '../../providers/console_provider.dart';
import '../../storage/diff_file_adapter.dart';
import '../../storage/package_file_adapter.dart';
import '../../storage/package_file_hierarchy.dart';
import '../commands/add_group_command.dart';
import '../commands/expand_group_command.dart';
import '../commands/pacman_command.dart';
import '../commands/print_command.dart';
import '../commands/prompt_command.dart';
import '../commands/update_history_command.dart';
import '../prompter.dart';
import 'command_editor.dart';

part 'diff_editor.g.dart';

// coverage:ignore-start
@riverpod
DiffEditor diffEditor(Ref ref) => DiffEditor(
  ref.read(consoleProvider),
  ref.read(prompterProvider),
  ref.read(packageFileAdapterProvider),
  ref.read(diffFileAdapterProvider),
  ref.read(pacmanProvider),
);
// coverage:ignore-end

final class DiffEditor extends CommandEditor<DiffEntry> {
  final PackageFileAdapter _packageFileAdapter;
  final DiffFileAdapter _diffFileAdapter;
  final Pacman _pacman;

  DiffEditor(
    super.console,
    super.prompter,
    this._packageFileAdapter,
    this._diffFileAdapter,
    this._pacman,
  );

  @override
  Stream<DiffEntry> loadTargets(
    String machineName,
    PackageFileHierarchy hierarchy,
  ) => _diffFileAdapter.loadPackageDiff(machineName);

  @override
  String packageForTarget(DiffEntry target) => target.package;

  @override
  Stream<PromptCommand> buildCommands(
    String machineName,
    PackageFileHierarchy hierarchy,
    DiffEntry target,
  ) => switch (target) {
    DiffAddedEntry(:final package) => _presentAdded(
      package,
      hierarchy.packageFiles,
    ),
    DiffRemovedEntry(:final package) => _presentRemoved(
      package,
      machineName,
      hierarchy.groupsByPackages,
    ),
  };

  Stream<PromptCommand> _presentAdded(
    String package,
    Iterable<String> machineHierarchy,
  ) async* {
    super.prompter.writeTitle(
      message:
          'Found installed package **$package** '
          'that is not in the history yet!',
      color: ConsoleColor.green,
    );

    yield PrintCommand.local(super.console, _pacman);
    yield RemoveCommand(super.console, _pacman, super.prompter);
    yield MarkImplicitlyInstalledCommand(
      super.console,
      _pacman,
      super.prompter,
    );
    final addHistoryCommands = AddHistoryCommand.generate(
      super.console,
      _packageFileAdapter,
      super.prompter,
      machineHierarchy,
    );
    for (final addHistoryCommand in addHistoryCommands) {
      yield addHistoryCommand;
    }
    yield AddGroupCommand(
      super.console,
      _packageFileAdapter,
      _pacman,
      super.prompter,
      machineHierarchy,
    );
  }

  Stream<PromptCommand> _presentRemoved(
    String package,
    String machineName,
    Map<String, Set<String>> knownGroups,
  ) async* {
    final isInstalled = await _pacman.checkIfPackageIsInstalled(package);
    final firstGroup = knownGroups[package]?.firstOrNull;

    final messageBuffer =
        StringBuffer()
          ..write('Found ')
          ..write(isInstalled ? 'implicitly installed' : 'uninstalled')
          ..write(' package **')
          ..write(package);
    if (firstGroup != null) {
      messageBuffer
        ..write('** belonging to group **')
        ..write(firstGroup);
    }
    messageBuffer.write('** that is in the history!');

    super.prompter.writeTitle(
      message: messageBuffer.toString(),
      color: switch ((firstGroup, isInstalled)) {
        (String(), true) => ConsoleColor.cyan,
        (String(), false) => ConsoleColor.blue,
        (null, true) => ConsoleColor.yellow,
        (null, false) => ConsoleColor.red,
      },
    );

    if (isInstalled) {
      yield PrintCommand.local(super.console, _pacman);
      yield MarkExplicitlyInstalledCommand(
        super.console,
        _pacman,
        super.prompter,
      );
    } else {
      yield PrintCommand.remote(super.console, _pacman);
      yield InstallCommand(super.console, _pacman, super.prompter);
    }

    if (firstGroup != null) {
      yield ExpandGroupCommand(
        super.console,
        _packageFileAdapter,
        _pacman,
        super.prompter,
        machineName: machineName,
        group: firstGroup,
      );
    } else {
      yield RemoveHistoryCommand(
        super.console,
        _packageFileAdapter,
        super.prompter,
        machineName,
      );
    }
  }
}
