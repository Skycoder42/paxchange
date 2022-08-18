import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/commands/skip_command.dart';
import 'package:test/test.dart';

import 'pacman_command_test.dart';

void main() {
  group('$SkipCommand', () {
    test('always returns true', () {
      const sut = SkipCommand();

      expect(sut.key, 's');
      expect(sut.description, isNotEmpty);
      expect(sut(MockConsole(), ''), PromptResult.skipped);
    });
  });
}
