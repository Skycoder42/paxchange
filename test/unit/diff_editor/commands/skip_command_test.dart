import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/commands/skip_command.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

void main() {
  group('$SkipCommand', () {
    test('always returns skipped', () {
      final sut = SkipCommand(MockConsole());

      expect(sut.key, 's');
      expect(sut.description, isNotEmpty);
      expect(sut(), PromptResult.skipped);
    });
  });
}
