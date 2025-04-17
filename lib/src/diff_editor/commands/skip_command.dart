import 'package:dart_console/dart_console.dart';

import 'prompt_command.dart';

final class SkipCommand extends PromptCommand {
  const SkipCommand(Console console) : super(console, '');

  @override
  String get key => 's';

  @override
  String get description => 'Skip this package for now';

  @override
  PromptResult call() => PromptResult.skipped;
}
