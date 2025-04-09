import 'prompt_command.dart';

final class SkipCommand extends PromptCommand {
  const SkipCommand(super.console);

  @override
  String get key => 's';

  @override
  String get description => 'Skip this package for now';

  @override
  PromptResult call(String packageName) => PromptResult.skipped;
}
