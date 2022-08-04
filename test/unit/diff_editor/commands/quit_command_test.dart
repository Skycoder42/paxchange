import 'package:paxchange/src/diff_editor/commands/quit_command.dart';
import 'package:test/test.dart';

import 'pacman_command_test.dart';

void main() {
  group('$QuitCommand', () {
    test('always returns false', () {
      const sut = QuitCommand();

      expect(sut.key, 'q');
      expect(sut.description, isNotEmpty);
      expect(sut(MockConsole(), ''), isFalse);
    });
  });
}
