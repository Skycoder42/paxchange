import 'package:dart_console/dart_console.dart';

import 'prompt_command.dart';

class QuitCommand extends PromptCommand {
  const QuitCommand();

  @override
  String get key => 'q';

  @override
  String get description => 'Quit the application';

  @override
  PromptResult call(Console console, String packageName) => PromptResult.quit;
}
