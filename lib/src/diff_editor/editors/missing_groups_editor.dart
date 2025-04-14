import 'package:dart_console/dart_console.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/console_provider.dart';
import '../../storage/package_file_adapter.dart';
import '../../storage/package_file_hierarchy.dart';
import 'command_editor.dart';
import '../commands/prompt_command.dart';
import '../commands/update_history_command.dart';
import '../prompter.dart';

part 'missing_groups_editor.g.dart';

// coverage:ignore-start
@riverpod
MissingGroupsEditor missingGroupsEditor(Ref ref) => MissingGroupsEditor(
  ref.watch(consoleProvider),
  ref.watch(prompterProvider),
  ref.watch(packageFileAdapterProvider),
);
// coverage:ignore-end

final class MissingGroupsEditor extends CommandEditor<String> {
  final PackageFileAdapter _packageFileAdapter;

  MissingGroupsEditor(super.console, super.prompter, this._packageFileAdapter);

  @override
  Stream<String> loadTargets(
    String machineName,
    PackageFileHierarchy hierarchy,
  ) => Stream.fromIterable(hierarchy.missingGroups);

  @override
  String packageForTarget(String target) => target;

  @override
  Stream<PromptCommand> buildCommands(
    String machineName,
    PackageFileHierarchy hierarchy,
    String target,
  ) async* {
    super.prompter.writeTitle(
      message: 'Found non existing group **$target** in the history!',
      color: ConsoleColor.magenta,
    );

    yield RemoveHistoryCommand(
      super.console,
      _packageFileAdapter,
      super.prompter,
      machineName,
      isGroup: true,
    );
  }
}
