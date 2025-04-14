import 'package:args/command_runner.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../config.dart';
import '../diff_editor/editors/cleanup_editor.dart';
import '../diff_editor/editors/diff_editor.dart';
import '../diff_editor/editor.dart';
import '../diff_editor/editors/missing_groups_editor.dart';

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

  @CliOption(
    defaultsTo: false,
    help:
        'When enabled, the cleanup will include packages '
        'that are referenced as optional dependency.',
  )
  final bool includeOptional;

  const ReviewOptions({
    required this.machineName,
    required this.includeOptional,
  });
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

    final editors = [
      _providerContainer.read(missingGroupsEditorProvider),
      _providerContainer.read(diffEditorProvider),
      _providerContainer.read(
        cleanupEditorProvider(includeOptional: _options.includeOptional),
      ),
    ];

    final editor = _providerContainer.read(editorProvider(editors));

    await editor.run(machineName ?? config.rootPackageFile);

    return 0;
  }
}
