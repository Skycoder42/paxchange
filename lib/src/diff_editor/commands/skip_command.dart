import 'package:dart_console/dart_console.dart';

import 'prompt_command.dart';

final class const SkipCommand(Console console) extends PromptCommand {
  this : super(console, '');

  @override
  String get key => 's';

  @override
  String get description => 'Skip this package for now';

  @override
  PromptResult call() => PromptResult.skipped;
}
