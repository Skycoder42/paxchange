import 'package:args/command_runner.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../config.dart';
import '../diff_editor/diff_editor.dart';

part 'review_command.g.dart';

@immutable
@CliOptions(createCommand: true)
final class ReviewOptions {
  @CliOption(
    abbr: 'n',
    valueHelp: 'name',
    help:
        'Specify a custom machine name to review the diff for. '
        'By default, this machine is used.',
  )
  final String? machineName;

  const ReviewOptions({required this.machineName});
}

class ReviewCommand extends _$ReviewOptionsCommand<int> {
  final ProviderContainer _providerContainer;

  @override
  String get name => 'review';

  @override
  String get description => 'Review the package diff for the given machine.';

  @override
  bool get takesArguments => false;

  ReviewCommand(this._providerContainer);

  @override
  Future<int> run() async {
    final machineName = _options.machineName;
    final config = _providerContainer.read(configProvider);
    final diffEditor = _providerContainer.read(diffEditorProvider);

    await diffEditor.run(machineName ?? config.rootPackageFile);

    return 0;
  }
}
