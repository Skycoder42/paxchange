import 'package:dart_console/dart_console.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../diff_entry.dart';
import '../package_sync.dart';
import '../pacman/pacman.dart';
import '../providers/console_provider.dart';
import '../storage/diff_file_adapter.dart';
import '../storage/package_file_adapter.dart';
import 'commands/add_group_command.dart';
import 'commands/pacman_command.dart';
import 'commands/print_command.dart';
import 'commands/prompt_command.dart';
import 'commands/quit_command.dart';
import 'commands/skip_command.dart';
import 'commands/update_history_command.dart';
import 'prompter.dart';

part 'diff_editor.g.dart';

// coverage:ignore-start
@riverpod
DiffEditor diffEditor(Ref ref) => DiffEditor(
  ref.read(packageFileAdapterProvider),
  ref.read(diffFileAdapterProvider),
  ref.read(pacmanProvider),
  ref.read(packageSyncProvider),
  ref.read(consoleProvider),
  ref.read(prompterProvider),
);
// coverage:ignore-end

class DiffEditor {
  final PackageFileAdapter _packageFileAdapter;
  final DiffFileAdapter _diffFileAdapter;
  final Pacman _pacman;
  final PackageSync _packageSync;
  final Console _console;
  final Prompter _prompter;

  DiffEditor(
    this._packageFileAdapter,
    this._diffFileAdapter,
    this._pacman,
    this._packageSync,
    this._console,
    this._prompter,
  );

  Future<void> run(String machineName) async {
    if (!_console.hasTerminal) {
      throw Exception('Cannot run without an interactive ANSI terminal!');
    }

    await _packageFileAdapter.ensurePackageFileExists(machineName);

    final machineHierarchy =
        await _packageFileAdapter
            .loadPackageFileHierarchy(machineName)
            .toList();

    var reload = false;
    do {
      final diffEntries = _diffFileAdapter.loadPackageDiff(machineName);

      var didModify = false;
      await for (final diffEntry in diffEntries) {
        final entryResult = await switch (diffEntry) {
          DiffAddedEntry(:final package) => _presentAdded(
            package,
            machineHierarchy,
          ),
          DiffRemovedEntry(:final package) => _presentRemoved(
            package,
            machineName,
          ),
        };

        reload = entryResult.needsReload;
        didModify = didModify || entryResult.didModify;
        if (entryResult.stopProcessing) {
          break;
        }
      }

      if (didModify) {
        await _updatePackageDiff(skipResultMessage: reload);
      } else {
        _console.writeLine('No packages modified, nothing to do!');
      }
    } while (reload);
  }

  Future<PromptResult> _presentAdded(
    String package,
    List<String> machineHierarchy,
  ) async {
    _prompter.writeTitle(
      messagePrefix: 'Found installed package ',
      messageHighlight: package,
      messageSuffix: ' that is not in the history yet!',
      color: ConsoleColor.green,
    );

    return _prompter.promptCommand(
      packageName: package,
      commands: [
        PrintCommand.local(_pacman, _console),
        RemoveCommand(_pacman, _prompter, _console),
        MarkImplicitlyInstalledCommand(_pacman, _prompter, _console),
        ...AddHistoryCommand.generate(
          _packageFileAdapter,
          machineHierarchy,
          _console,
        ),
        AddGroupCommand(
          _packageFileAdapter,
          _pacman,
          _prompter,
          machineHierarchy,
          _console,
        ),
        SkipCommand(_console),
        QuitCommand(_console),
      ],
    );
  }

  Future<PromptResult> _presentRemoved(
    String package,
    String machineName,
  ) async {
    final isInstalled = await _pacman.checkIfPackageIsInstalled(package);
    if (isInstalled) {
      return _presentImplicitlyInstalled(package, machineName);
    } else {
      return _presentUninstalled(package, machineName);
    }
  }

  Future<PromptResult> _presentImplicitlyInstalled(
    String package,
    String machineName,
  ) async {
    _prompter.writeTitle(
      messagePrefix: 'Found implicitly installed package ',
      messageHighlight: package,
      messageSuffix: ' that is in the history!',
      color: ConsoleColor.yellow,
    );

    return _prompter.promptCommand(
      packageName: package,
      commands: [
        PrintCommand.local(_pacman, _console),
        MarkExplicitlyInstalledCommand(_pacman, _prompter, _console),
        RemoveHistoryCommand(_packageFileAdapter, machineName, _console),
        SkipCommand(_console),
        QuitCommand(_console),
      ],
    );
  }

  Future<PromptResult> _presentUninstalled(
    String package,
    String machineName,
  ) async {
    _prompter.writeTitle(
      messagePrefix: 'Found uninstalled package ',
      messageHighlight: package,
      messageSuffix: ' that is in the history!',
      color: ConsoleColor.red,
    );

    return _prompter.promptCommand(
      packageName: package,
      commands: [
        PrintCommand.remote(_pacman, _console),
        InstallCommand(_pacman, _prompter, _console),
        RemoveHistoryCommand(_packageFileAdapter, machineName, _console),
        SkipCommand(_console),
        QuitCommand(_console),
      ],
    );
  }

  Future<void> _updatePackageDiff({bool skipResultMessage = false}) async {
    _console
      ..clearScreen()
      ..writeLine('Updating package changelog, please wait...');

    final result = await _packageSync.updatePackageDiff();

    if (!skipResultMessage) {
      _console
        ..writeLine('Successfully regenerated package changelog!')
        ..writeLine('It now contains $result entries');
    }
  }
}
