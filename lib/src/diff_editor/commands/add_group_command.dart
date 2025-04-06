import 'dart:async';

import 'package:dart_console/dart_console.dart';

import '../../pacman/pacman.dart';
import '../../storage/package_file_adapter.dart';
import '../prompter.dart';
import 'prompt_command.dart';

class AddGroupCommand extends PromptCommand {
  final PackageFileAdapter _packageFileAdapter;
  final Pacman _pacman;
  final Prompter _prompter;

  const AddGroupCommand(this._packageFileAdapter, this._pacman, this._prompter);

  @override
  String get key => 'g';

  @override
  String get description => 'Add a group of package to the package history';

  @override
  Future<PromptResult> call(Console console, String packageName) async {
    final packageGroups =
        await _pacman
            .queryInstalledPackage(packageName)
            .where((line) => line.startsWith('Groups'))
            .map((line) => line.substring(line.indexOf(':') + 1).trim())
            .expand((line) => line.split(RegExp(r'\s+')))
            .map((group) => group.trim())
            .toList();

    console.writeLine();
    final selectedGroup = _prompter.promptOption(
      console: console,
      description: 'Which group of $packageName do you want to add?',
      options: {
        for (final (index, group) in packageGroups.indexed) '$index': group,
        'c': 'Cancel and return to main menu',
      },
    );

    if (selectedGroup == 'c') {
      return PromptResult.repeat;
    }

    throw UnimplementedError();
  }
}
