import 'prompt_command.dart';

final class QuitCommand extends PromptCommand {
  const QuitCommand(super.console);

  @override
  String get key => 'q';

  @override
  String get description => 'Quit the application';

  @override
  PromptResult call(String packageName) => PromptResult.quit;
}
