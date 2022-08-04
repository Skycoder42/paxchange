import 'dart:io';

import 'package:dart_console/dart_console.dart';

import '../package_sync.dart';
import '../pacman/pacman.dart';
import '../storage/diff_file_adapter.dart';
import '../storage/package_file_adapter.dart';
import 'commands/pacman_command.dart';
import 'commands/print_command.dart';
import 'commands/prompt_command.dart';
import 'commands/quit_command.dart';
import 'commands/skip_command.dart';
import 'commands/update_history_command.dart';

class DiffEditor {
  final String _rootPackageName;
  final PackageFileAdapter _packageFileAdapter;
  final DiffFileAdapter _diffFileAdapter;
  final Pacman _pacman;
  final PackageSync _packageSync;

  final _console = Console.scrolling();

  DiffEditor(
    this._rootPackageName,
    this._packageFileAdapter,
    this._diffFileAdapter,
    this._pacman,
    this._packageSync,
  );

  Future<void> run() async {
    if (!_console.hasTerminal || !stdout.supportsAnsiEscapes) {
      throw Exception('Cannot run without an interactive ANSI terminal!');
    }

    final machineHierarchy = await _packageFileAdapter
        .loadPackageFileHierarchy(_rootPackageName)
        .toList();
    final diffEntries = _diffFileAdapter.loadPackageDiff(_rootPackageName);

    await for (final diffEntry in diffEntries) {
      final entryResult = await diffEntry.when(
        added: (package) => _presentAdded(package, machineHierarchy),
        removed: (package) => _presentRemoved(package, _rootPackageName),
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
    _writeTitle(
      messagePrefix: 'Found installed package ',
      package: package,
      messageSuffix: ' that is not in history yet!',
      color: ConsoleColor.green,
    );

    return PromptCommand.prompt(_console, package, [
      PrintCommand.local(_pacman),
      RemoveCommand(_pacman),
      ...AddHistoryCommand.generate(_packageFileAdapter, machineHierarchy),
      const SkipCommand(),
      const QuitCommand(),
    ]);
  }

  Future<bool> _presentRemoved(String package, String machineName) async {
    _writeTitle(
      messagePrefix: 'Found uninstalled package ',
      package: package,
      messageSuffix: ' that is in the history!',
      color: ConsoleColor.red,
    );

    return PromptCommand.prompt(_console, package, [
      PrintCommand.remote(_pacman),
      InstallCommand(_pacman),
      RemoveHistoryCommand(_packageFileAdapter, machineName),
      const SkipCommand(),
      const QuitCommand(),
    ]);
  }

  void _writeTitle({
    required String messagePrefix,
    required String package,
    required String messageSuffix,
    required ConsoleColor color,
  }) {
    _console
      ..resetColorAttributes()
      ..clearScreen()
      ..setForegroundColor(color)
      ..write(messagePrefix)
      ..setTextStyle(bold: true)
      ..write(package)
      ..setTextStyle()
      ..setForegroundColor(color)
      ..writeLine(messageSuffix)
      ..resetColorAttributes();
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
