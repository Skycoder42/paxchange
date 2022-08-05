import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:riverpod/riverpod.dart';

import '../package_sync.dart';
import '../pacman/pacman.dart';
import '../storage/diff_file_adapter.dart';
import '../storage/package_file_adapter.dart';
import 'commands/pacman_command.dart';
import 'commands/print_command.dart';
import 'commands/quit_command.dart';
import 'commands/skip_command.dart';
import 'commands/update_history_command.dart';
import 'prompter.dart';

// coverage:ignore-start
final diffEditorProvider = Provider(
  (ref) => DiffEditor(
    ref.read(packageFileAdapterProvider),
    ref.read(diffFileAdapterProvider),
    ref.read(pacmanProvider),
    ref.read(packageSyncProvider),
    ref.read(prompterProvider),
  ),
);
// coverage:ignore-end

class DiffEditor {
  final PackageFileAdapter _packageFileAdapter;
  final DiffFileAdapter _diffFileAdapter;
  final Pacman _pacman;
  final PackageSync _packageSync;
  final Prompter _prompter;

  final _console = Console.scrolling();

  DiffEditor(
    this._packageFileAdapter,
    this._diffFileAdapter,
    this._pacman,
    this._packageSync,
    this._prompter,
  );

  Future<void> run(String machineName) async {
    if (!_console.hasTerminal || !stdout.supportsAnsiEscapes) {
      throw Exception('Cannot run without an interactive ANSI terminal!');
    }

    final machineHierarchy = await _packageFileAdapter
        .loadPackageFileHierarchy(machineName)
        .toList();
    final diffEntries = _diffFileAdapter.loadPackageDiff(machineName);

    await for (final diffEntry in diffEntries) {
      final entryResult = await diffEntry.when(
        added: (package) => _presentAdded(package, machineHierarchy),
        removed: (package) => _presentRemoved(package, machineName),
      );

      if (!entryResult) {
        break;
      }
    }

    await _updatePackageDiff();
  }

  Future<bool> _presentAdded(
    String package,
    List<String> machineHierarchy,
  ) async {
    _prompter.writeTitle(
      console: _console,
      messagePrefix: 'Found installed package ',
      package: package,
      messageSuffix: ' that is not in the history yet!',
      color: ConsoleColor.green,
    );

    return _prompter.prompt(
      console: _console,
      packageName: package,
      commands: [
        PrintCommand.local(_pacman),
        RemoveCommand(_pacman),
        ...AddHistoryCommand.generate(_packageFileAdapter, machineHierarchy),
        const SkipCommand(),
        const QuitCommand(),
      ],
    );
  }

  Future<bool> _presentRemoved(String package, String machineName) async {
    _prompter.writeTitle(
      console: _console,
      messagePrefix: 'Found uninstalled package ',
      package: package,
      messageSuffix: ' that is in the history!',
      color: ConsoleColor.red,
    );

    return _prompter.prompt(
      console: _console,
      packageName: package,
      commands: [
        PrintCommand.remote(_pacman),
        InstallCommand(_pacman),
        RemoveHistoryCommand(_packageFileAdapter, machineName),
        const SkipCommand(),
        const QuitCommand(),
      ],
    );
  }

  Future<void> _updatePackageDiff() async {
    _console
      ..clearScreen()
      ..writeLine('Updating package changelog, please wait...');

    final result = await _packageSync.updatePackageDiff();

    _console
      ..writeLine('Successfully regenerated package changelog!')
      ..writeLine('It now contains $result entries');
  }
}
