import 'package:args/command_runner.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../config.dart';
import '../diff_editor/diff_editor.dart';

class ReviewCommand extends Command<int> {
  @visibleForTesting
  static const machineNameOption = 'machine-name';

  final ProviderContainer _providerContainer;

  @override
  String get name => 'review';

  @override
  String get description => 'Review the package diff for the given machine.';

  @override
  bool get takesArguments => false;

  ReviewCommand(this._providerContainer) {
    argParser.addOption(
      machineNameOption,
      abbr: 'n',
      aliases: const ['name', 'machine'],
      valueHelp: 'name',
      help: 'Specify a custom machine name to review the diff for. '
          'By default, this machine is used.',
    );
  }

  @override
  Future<int> run() async {
    final machineName = argResults![machineNameOption] as String?;
    final config = _providerContainer.read(configProvider);
    final diffEditor = _providerContainer.read(diffEditorProvider);

    await diffEditor.run(machineName ?? config.rootPackageFile);

    return 0;
  }
}
