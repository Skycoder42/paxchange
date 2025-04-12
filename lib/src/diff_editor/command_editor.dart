import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../storage/package_file_hierarchy.dart';
import 'commands/prompt_command.dart';
import 'prompter.dart';

abstract class CommandEditor<TTarget> {
  @protected
  final Console console;
  @protected
  final Prompter prompter;

  CommandEditor(this.console, this.prompter);

  Stream<TTarget> loadTargets(
    String machineName,
    PackageFileHierarchy hierarchy,
  );

  String packageForTarget(TTarget target);

  Stream<PromptCommand> buildCommands(
    String machineName,
    PackageFileHierarchy hierarchy,
    TTarget target,
  );
}
