import 'dart:async';

import '../../pacman/pacman.dart';
import '../../storage/package_file_adapter.dart';
import '../prompter.dart';
import 'prompt_command.dart';
import 'update_history_command.dart';

final class AddGroupCommand extends PromptCommand {
  final PackageFileAdapter _packageFileAdapter;
  final Pacman _pacman;
  final Prompter _prompter;

  final Iterable<String> machineHierarchy;

  const AddGroupCommand(
    super.console,
    this._packageFileAdapter,
    this._pacman,
    this._prompter,
    this.machineHierarchy,
    super.packageName,
  );

  @override
  String get key => 'g';

  @override
  String get description => 'Add a group of the package to the history';

  @override
  Future<PromptResult> call() async {
    final packageGroups = await _getPackageGroups(packageName);
    if (packageGroups.isEmpty) {
      console.writeLine('No groups found for $packageName');
      return PromptResult.repeat;
    }

    final group = _selectGroup(packageName, packageGroups);
    if (group == null) {
      return PromptResult.repeat;
    }

    final addCommand = _selectAddCommand(group);
    if (addCommand == null) {
      return PromptResult.repeat;
    }

    await _deleteGroupPackagesFromHistory(addCommand.machineName, group);
    final result = await addCommand();
    return result.withReload();
  }

  Future<List<String>> _getPackageGroups(String packageName) async {
    final groups =
        await _pacman
            .queryInstalledPackage(packageName)
            .where((line) => line.startsWith('Groups'))
            .map((line) => line.substring(line.indexOf(':') + 1).trim())
            .expand((line) => line.split(RegExp(r'\s+')))
            .map((group) => group.trim())
            .toList();
    if (groups.length == 1 && groups.single == 'None') {
      return const [];
    }
    return groups;
  }

  String? _selectGroup(String packageName, List<String> packageGroups) {
    final selectedGroup = _prompter.promptOption(
      description: 'Which group of $packageName do you want to add?',
      options: {
        for (final (index, group) in packageGroups.indexed) '$index': group,
        'c': 'Cancel and return to main menu',
      },
    );

    if (selectedGroup == 'c') {
      return null;
    }

    return packageGroups[int.parse(selectedGroup)];
  }

  AddHistoryCommand? _selectAddCommand(String group) {
    final addCommands = AddHistoryCommand.generate(
      console,
      _packageFileAdapter,
      _prompter,
      machineHierarchy,
      '::group $group',
    );
    final selectedCommand = _prompter.promptOption(
      description: 'Which package history do you want to add $group to?',
      options: {
        for (final command in addCommands) command.key: command.description,
        'c': 'Cancel and return to main menu',
      },
    );

    if (selectedCommand == 'c') {
      return null;
    }

    return addCommands.singleWhere((c) => c.key == selectedCommand);
  }

  Future<void> _deleteGroupPackagesFromHistory(
    String machineName,
    String group,
  ) async {
    console
      ..writeLine()
      ..writeLine('Removing packages of group $group from history...');
    await for (final package in _pacman.listPackagesForGroup(group)) {
      final didRemove = await _packageFileAdapter.removeFromPackageFile(
        machineName,
        package,
        recursive: false,
      );
      if (didRemove) {
        console.writeLine('-> Removed $package');
      }
    }
  }
}
