import 'package:dart_console/dart_console.dart';

import 'prompt_command.dart';

final class QuitCommand extends PromptCommand {
  const QuitCommand(Console console) : super(console, '');

  @override
  String get key => 'q';

  @override
  String get description => 'Quit the application';

  @override
  PromptResult call() => PromptResult.quit;
}
