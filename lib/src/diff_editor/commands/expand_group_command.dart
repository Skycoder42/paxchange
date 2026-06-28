import 'dart:async';

import 'package:dart_console/dart_console.dart';

import '../../pacman/pacman.dart';
import '../../storage/package_file_adapter.dart';
import '../prompter.dart';
import 'prompt_command.dart';

final class ExpandGroupCommand extends PromptCommand {
  final PackageFileAdapter _packageFileAdapter;
  final Pacman _pacman;
  final Prompter _prompter;
  final String machineName;
  final String group;

  ExpandGroupCommand(
    Console console,
    this._packageFileAdapter,
    this._pacman,
    this._prompter, {
    required String packageName,
    required this.machineName,
    required this.group,
  }) : super(console, packageName);

  @override
  String get key => 'e';

  @override
  String get description => 'Expand group $group';

  @override
  Future<PromptResult> call() async {
    final packagesInGroup = await _pacman
        .listInstalledPackagesForGroup(group)
        .where((p) => p != packageName)
        .toList();

    final didRemove = await _packageFileAdapter.removeFromPackageFile(
      machineName,
      group,
      isGroup: true,
      replacement: packagesInGroup,
    );

    if (didRemove) {
      return PromptResult.succeededReload;
    } else {
      _prompter.writeError('Failed to remove group $group from $machineName!');
      return PromptResult.failed;
    }
  }
}
