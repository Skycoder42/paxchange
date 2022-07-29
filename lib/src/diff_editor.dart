import 'dart:io';

import 'package:dart_console/dart_console.dart';

import 'diff_entry.dart';
import 'pacman/pacman.dart';
import 'storage/package_file_adapter.dart';

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
    _console
      ..clearScreen()
      ..setForegroundColor(ConsoleColor.green)
      ..write('Found installed package ')
      ..setTextStyle(bold: true)
      ..write(package)
      ..setTextStyle()
      ..setForegroundColor(ConsoleColor.green)
      ..writeLine(' that is not in history yet!')
      ..resetColorAttributes();

    return _presentAddedOption(package);
  }

  Future<bool> _presentAddedOption(String package) async {
    while (true) {
      _console.writeLine('What do you want to do?');

      _writeOption('p', 'Print information about the package');
      _writeOption('r', 'Remove the package from this machine');

      for (var i = 0; i < _machineHierarchy.length; ++i) {
        _writeOption('$i', 'Add package to ${_machineHierarchy[i]}');
      }

      _writeOption('s', 'Skip this package for now');
      _writeOption('q', 'Quit the application');

      _console
        ..write('> ')
        ..setTextStyle(blink: true);
      final key = _console.readKey();
      _console.setTextStyle();
      switch (key.char) {
        case 'p':
          await _writePackageInfo(_pacman.queryInstalledPackage(package));
          continue;
        case 'r':
          if (await _uninstallPackage(package)) {
            return true;
          }
          continue;
        case 's':
          return true;
        case 'q':
          return false;
        default:
          break;
      }

      final index = int.tryParse(key.char);
      if (index == null || index >= _machineHierarchy.length) {
        _console
          ..setForegroundColor(ConsoleColor.red)
          ..writeErrorLine('Invalid option: ${key.char}!')
          ..writeLine()
          ..resetColorAttributes();
        continue;
      }

      await _addPackageToPackageFile(_machineHierarchy[index], package);
      return true;
    }
  }

  void _writeOption(String key, String description) {
    _console
      ..write('  ')
      ..setForegroundColor(ConsoleColor.blue)
      ..write(key)
      ..resetColorAttributes()
      ..write(': $description\n');
  }

  Future<void> _writePackageInfo(Stream<String> packageInfo) async {
    _console.clearScreen();
    await packageInfo.forEach(_console.writeLine);
    _console.writeLine();
  }

  Future<bool> _uninstallPackage(String package) async {
    _console.clearScreen();
    final exitCode = await _pacman.removePackage(package);
    if (exitCode == 0) {
      _console
        ..writeLine()
        ..writeLine(
          'Successfully removed $package. Press any key to continue...',
        )
        ..readKey();
      return true;
    } else {
      _console
        ..setForegroundColor(ConsoleColor.red)
        ..writeLine()
        ..writeErrorLine(
          'Failed to removed $package! '
          'Package manager failed with exit code $exitCode.',
        )
        ..writeLine()
        ..resetColorAttributes();
      return false;
    }
  }

  Future<void> _addPackageToPackageFile(
    String packageFile,
    String package,
  ) async {
    _console
      ..writeLine()
      ..writeLine('Adding $package to $packageFile...');
    await _packageFileAdapter.addToPackageFile(
      packageFile,
      package,
    );
    _console
      ..writeLine('Success! Press any key to continue...')
      ..readKey();
  }

  Future<bool> _presentRemoved(String package) async {
    _console
      ..clearScreen()
      ..setForegroundColor(ConsoleColor.red)
      ..write('Found uninstalled package ')
      ..setTextStyle(bold: true)
      ..write(package)
      ..setTextStyle()
      ..setForegroundColor(ConsoleColor.red)
      ..writeLine(' that is in the history!')
      ..resetColorAttributes();

    return _presentRemovedOption(package);
  }

  Future<bool> _presentRemovedOption(String package) async {
    while (true) {
      _console.writeLine('What do you want to do?');

      _writeOption('p', 'Print information about the package');
      _writeOption('i', 'Install the package on this machine');
      _writeOption('d', 'Delete the package from the package history');
      _writeOption('s', 'Skip this package for now');
      _writeOption('q', 'Quit the application');

      _console
        ..write('> ')
        ..setTextStyle(blink: true);
      final key = _console.readKey();
      _console.setTextStyle();
      switch (key.char) {
        case 'p':
          await _writePackageInfo(_pacman.queryUninstalledPackage(package));
          continue;
        case 'i':
          if (await _installPackage(package)) {
            return true;
          }
          continue;
        case 'd':
          await _removePackageFromPackageHistory(package);
          return true;
        case 's':
          return true;
        case 'q':
          return false;
        default:
          _console
            ..setForegroundColor(ConsoleColor.red)
            ..writeErrorLine('Invalid option: ${key.char}!')
            ..writeLine()
            ..resetColorAttributes();
          continue;
      }
    }
  }

  Future<bool> _installPackage(String package) async {
    _console.clearScreen();
    final exitCode = await _pacman.installPackage(package);
    if (exitCode == 0) {
      _console
        ..writeLine()
        ..writeLine(
          'Successfully installed $package. Press any key to continue...',
        )
        ..readKey();
      return true;
    } else {
      _console
        ..setForegroundColor(ConsoleColor.red)
        ..writeLine()
        ..writeErrorLine(
          'Failed to install $package! '
          'Package manager failed with exit code $exitCode.',
        )
        ..writeLine()
        ..resetColorAttributes();
      return false;
    }
  }

  Future<void> _removePackageFromPackageHistory(String package) async {
    _console
      ..writeLine()
      ..writeLine('Removing $package from $_machineName...');
    await _packageFileAdapter.removeFromPackageFile(
      _machineName,
      package,
    );
    _console
      ..writeLine('Success! Press any key to continue...')
      ..readKey();
  }
}
