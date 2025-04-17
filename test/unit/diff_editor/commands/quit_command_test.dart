import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/commands/quit_command.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

void main() {
  group('$QuitCommand', () {
    test('always returns quit', () {
      final sut = QuitCommand(MockConsole());

      expect(sut.key, 'q');
      expect(sut.description, isNotEmpty);
      expect(sut(), PromptResult.quit);
    });
  });
}
