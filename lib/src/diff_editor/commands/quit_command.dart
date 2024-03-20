import 'package:dart_console2/dart_console2.dart';

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
