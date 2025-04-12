import 'dart:async';

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
    super.console,
    this._packageFileAdapter,
    this._pacman,
    this._prompter, {
    required this.machineName,
    required this.group,
  });

  @override
  String get key => 'e';

  @override
  String get description => 'Expand group $group';

  @override
  Future<PromptResult> call(String package) async {
    final packagesInGroup =
        await _pacman
            .listPackagesForGroup(group)
            .where((p) => p != package)
            .toList();

    final didRemove = await _packageFileAdapter.removeFromPackageFile(
      machineName,
      group,
      isGroup: true,
      replacement: packagesInGroup,
    );

    if (didRemove) {
      console
        ..writeLine('Success! Press any key to continue...')
        ..readKey();

      return PromptResult.succeededReload;
    } else {
      _prompter.writeError('Expanding group $group failed!');
      console
        ..writeLine('Press any key to continue...')
        ..readKey();

      return PromptResult.failed;
    }
  }
}
