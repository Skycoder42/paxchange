import 'package:dart_console/dart_console.dart';

import 'prompt_command.dart';

final class const QuitCommand(Console console) extends PromptCommand {
  this : super(console, '');

  @override
  String get key => 'q';

  @override
  String get description => 'Quit the application';

  @override
  PromptResult call() => PromptResult.quit;
}
