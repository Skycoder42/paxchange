import 'package:dart_console/dart_console.dart';

import 'prompt_command.dart';

class SkipCommand extends PromptCommand {
  const SkipCommand();

  @override
  String get key => 's';

  @override
  String get description => 'Skip this package for now';

  @override
  PromptResult call(Console console, String packageName) =>
      PromptResult.skipped;
}
