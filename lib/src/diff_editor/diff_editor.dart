import 'dart:io';

import 'package:dart_console/dart_console.dart';

import '../diff_entry.dart';
import '../pacman/pacman.dart';
import '../storage/package_file_adapter.dart';
import 'commands/pacman_command.dart';
import 'commands/print_command.dart';
import 'commands/prompt_command.dart';
import 'commands/quit_command.dart';
import 'commands/skip_command.dart';
import 'commands/update_history_command.dart';

class DiffEditor {
  final PackageFileAdapter _packageFileAdapter;
  final Pacman _pacman;

  final _console = Console.scrolling();

  late String _machineName;
  late List<String> _machineHierarchy;

  DiffEditor(
    this._packageFileAdapter,
    this._pacman,
  );

  Future<void> initializeFor(String machineName) async {
    if (!_console.hasTerminal || !stdout.supportsAnsiEscapes) {
      throw Exception('Cannot run without an interactive ANSI terminal!');
    }

    _machineName = machineName;
    _machineHierarchy = await _packageFileAdapter
        .loadPackageFileHierarchy(machineName)
        .toList();
  }

  Future<bool> presentDiff(DiffEntry diffEntry) => diffEntry.when(
        added: _presentAdded,
        removed: _presentRemoved,
      );

  Future<bool> _presentAdded(String package) async {
    _writeTitle(
      messagePrefix: 'Found installed package ',
      package: package,
      messageSuffix: ' that is not in history yet!',
      color: ConsoleColor.green,
    );

    return PromptCommand.prompt(_console, package, [
      PrintCommand.local(_pacman),
      RemoveCommand(_pacman),
      ...AddHistoryCommand.generate(_packageFileAdapter, _machineHierarchy),
      const SkipCommand(),
      const QuitCommand(),
    ]);
  }

  Future<bool> _presentRemoved(String package) async {
    _writeTitle(
      messagePrefix: 'Found uninstalled package ',
      package: package,
      messageSuffix: ' that is in the history!',
      color: ConsoleColor.red,
    );

    return PromptCommand.prompt(_console, package, [
      PrintCommand.remote(_pacman),
      InstallCommand(_pacman),
      RemoveHistoryCommand(_packageFileAdapter, _machineName),
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
}
