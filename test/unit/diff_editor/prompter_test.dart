import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

class MockPromptCommand extends Mock implements PromptCommand {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockConsole());
  });

  group('$Prompter', () {
    final mockConsole = MockConsole();

    setUp(() {
      reset(mockConsole);
    });

    test('writeError writes error line', () {
      const message = 'error-message';

      Prompter.writeError(mockConsole, message);

      verifyInOrder([
        () => mockConsole.setForegroundColor(ConsoleColor.red),
        () => mockConsole.writeLine(),
        () => mockConsole.writeLine(message),
        () => mockConsole.resetColorAttributes(),
      ]);
    });

    group('prompt', () {
      const testPackageName = 'test-package';
      final cmd1 = MockPromptCommand();
      final cmd2 = MockPromptCommand();

      setUp(() {
        when(() => cmd1.key).thenReturn('1');
        when(() => cmd1.description).thenReturn('command 1');
        when(() => cmd1.call(any(), any())).thenReturn(true);

        when(() => cmd2.key).thenReturn('2');
        when(() => cmd2.description).thenReturn('command 2');
        when(() => cmd2.call(any(), any())).thenReturn(false);
      });

      test('writes a prompt with all options and returns result of selected',
          () async {
        when(() => mockConsole.readKey()).thenReturn(Key.printable('1'));

        final result = await const Prompter().prompt(
          mockConsole,
          testPackageName,
          [cmd1, cmd2],
        );

        verifyInOrder([
          () => mockConsole.writeLine('What do you want to do?'),
          () => cmd1.writeOption(mockConsole),
          () => cmd2.writeOption(mockConsole),
          () => mockConsole.write('> '),
          () => mockConsole.setTextStyle(blink: true),
          () => mockConsole.readKey(),
          () => mockConsole.setTextStyle(),
          () => cmd1.call(mockConsole, testPackageName),
        ]);
        expect(result, isTrue);
      });

      test('writes a looping prompt for invalid inputs', () async {
        var keyCtr = 3;
        when(() => mockConsole.readKey())
            .thenAnswer((i) => Key.printable('${keyCtr--}'));

        final result = await const Prompter().prompt(
          mockConsole,
          testPackageName,
          [cmd1, cmd2],
        );

        verifyInOrder([
          () => mockConsole.writeLine('What do you want to do?'),
          () => cmd1.writeOption(mockConsole),
          () => cmd2.writeOption(mockConsole),
          () => mockConsole.write('> '),
          () => mockConsole.setTextStyle(blink: true),
          () => mockConsole.readKey(),
          () => mockConsole.setTextStyle(),
          () => mockConsole.setForegroundColor(ConsoleColor.red),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine('Invalid option: 3!'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.writeLine('What do you want to do?'),
          () => cmd1.writeOption(mockConsole),
          () => cmd2.writeOption(mockConsole),
          () => mockConsole.write('> '),
          () => mockConsole.setTextStyle(blink: true),
          () => mockConsole.readKey(),
          () => mockConsole.setTextStyle(),
          () => cmd2.call(mockConsole, testPackageName),
        ]);
        expect(result, isFalse);
      });
    });
  });
}
