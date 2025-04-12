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
import 'commands/expand_group_command.dart';
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

    var reload = false;
    final skipped = <String>{};
    do {
      final packageFileHierarchy = await _packageFileAdapter
          .loadPackageFileHierarchy(machineName);

      if (!reload) {
        for (final group in packageFileHierarchy.missingGroups) {
          final result = await _presentMissingGroup(machineName, group);
          if (!result) {
            return;
          }
        }
      }

      final diffEntries = _diffFileAdapter.loadPackageDiff(machineName);
      var didModify = false;
      await for (final diffEntry in diffEntries) {
        if (skipped.contains(diffEntry.package)) {
          continue;
        }

        final entryResult = await switch (diffEntry) {
          DiffAddedEntry(:final package) => _presentAdded(
            package,
            packageFileHierarchy.packageFiles,
          ),
          DiffRemovedEntry(:final package) => _presentRemoved(
            package,
            machineName,
            packageFileHierarchy.groupsByPackages,
          ),
        };

        if (entryResult == PromptResult.skipped) {
          skipped.add(diffEntry.package);
        }
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
    Iterable<String> machineHierarchy,
  ) async {
    _prompter.writeTitle(
      message:
          'Found installed package **$package** '
          'that is not in the history yet!',
      color: ConsoleColor.green,
    );

    return _prompter.promptCommand(
      packageName: package,
      commands: [
        PrintCommand.local(_console, _pacman),
        RemoveCommand(_console, _pacman, _prompter),
        MarkImplicitlyInstalledCommand(_console, _pacman, _prompter),
        ...AddHistoryCommand.generate(
          _console,
          _packageFileAdapter,
          _prompter,
          machineHierarchy,
        ),
        AddGroupCommand(
          _console,
          _packageFileAdapter,
          _pacman,
          _prompter,
          machineHierarchy,
        ),
        SkipCommand(_console),
        QuitCommand(_console),
      ],
    );
  }

  Future<PromptResult> _presentRemoved(
    String package,
    String machineName,
    Map<String, Set<String>> knownGroups,
  ) async {
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

    _prompter.writeTitle(
      message: messageBuffer.toString(),
      color: switch ((firstGroup, isInstalled)) {
        (String(), _) => ConsoleColor.blue,
        (_, true) => ConsoleColor.yellow,
        (_, false) => ConsoleColor.red,
      },
    );

    return _prompter.promptCommand(
      packageName: package,
      commands: [
        if (isInstalled) ...[
          PrintCommand.local(_console, _pacman),
          MarkExplicitlyInstalledCommand(_console, _pacman, _prompter),
        ] else ...[
          PrintCommand.remote(_console, _pacman),
          InstallCommand(_console, _pacman, _prompter),
        ],
        if (firstGroup != null)
          ExpandGroupCommand(
            _console,
            _packageFileAdapter,
            _pacman,
            _prompter,
            machineName: machineName,
            group: firstGroup,
          )
        else
          RemoveHistoryCommand(
            _console,
            _packageFileAdapter,
            _prompter,
            machineName,
          ),
        SkipCommand(_console),
        QuitCommand(_console),
      ],
    );
  }

  Future<bool> _presentMissingGroup(String machineName, String group) async {
    _prompter.writeTitle(
      message: 'Found non existing group **$group** in the history!',
      color: ConsoleColor.magenta,
    );

    final result = _prompter.promptOption(
      description: 'Do you want to remove the group from the history?',
      options: const {'y': 'Yes', 'n': 'No', 'q': 'Quit the application'},
    );

    switch (result) {
      case 'y':
        await _packageFileAdapter.removeFromPackageFile(
          machineName,
          group,
          isGroup: true,
        );
        return true;
      case 'n':
        return true;
      default:
        return false;
    }
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
