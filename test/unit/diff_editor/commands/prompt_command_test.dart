import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

class MockPromptCommand extends Mock implements PromptCommand {}

class TestablePromptCommand extends PromptCommand {
  final mock = MockPromptCommand();

  @override
  String get key => mock.key;

  @override
  String get description => mock.description;

  @override
  FutureOr<bool> call(Console console, String packageName) =>
      mock.call(console, packageName);
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockConsole());
  });

  group('$PromptCommand', () {
    final mockConsole = MockConsole();

    setUp(() {
      reset(mockConsole);
    });

    test('writeOption writes single line with key and description', () {
      const testKey = 'test-key';
      const testDescription = 'test-description';
      final sut = TestablePromptCommand();
      when(() => sut.mock.key).thenReturn(testKey);
      when(() => sut.mock.description).thenReturn(testDescription);

      sut.writeOption(mockConsole);

      verifyInOrder([
        () => mockConsole.write('  '),
        () => mockConsole.setForegroundColor(ConsoleColor.blue),
        () => mockConsole.write(testKey),
        () => mockConsole.resetColorAttributes(),
        () => mockConsole.write(': $testDescription\n'),
      ]);
    });

    test('writeError writes error line', () {
      const message = 'error-message';

      // ignore: invalid_use_of_protected_member
      PromptCommand.writeError(mockConsole, message);

      verifyInOrder([
        () => mockConsole.setForegroundColor(ConsoleColor.red),
        () => mockConsole.writeLine(),
        () => mockConsole.writeLine(message),
        () => mockConsole.resetColorAttributes(),
      ]);
    });

    group('prompt', () {
      const testPackageName = 'test-package';
      final cmd1 = TestablePromptCommand();
      final cmd2 = TestablePromptCommand();

      setUp(() {
        when(() => cmd1.mock.key).thenReturn('1');
        when(() => cmd1.mock.description).thenReturn('command 1');
        when(() => cmd1.mock.call(any(), any())).thenReturn(true);

        when(() => cmd2.mock.key).thenReturn('2');
        when(() => cmd2.mock.description).thenReturn('command 2');
        when(() => cmd2.mock.call(any(), any())).thenReturn(false);
      });

      test('writes a prompt with all options and returns result of selected',
          () async {
        when(() => mockConsole.readKey()).thenReturn(Key.printable('1'));

        final result = await PromptCommand.prompt(
          mockConsole,
          testPackageName,
          [cmd1, cmd2],
        );

        verifyInOrder([
          () => mockConsole.writeLine('What do you want to do?'),
          () => mockConsole.write('  '),
          () => mockConsole.setForegroundColor(ConsoleColor.blue),
          () => mockConsole.write('1'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.write(': command 1\n'),
          () => mockConsole.write('  '),
          () => mockConsole.setForegroundColor(ConsoleColor.blue),
          () => mockConsole.write('2'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.write(': command 2\n'),
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

        final result = await PromptCommand.prompt(
          mockConsole,
          testPackageName,
          [cmd1, cmd2],
        );

        verifyInOrder([
          () => mockConsole.writeLine('What do you want to do?'),
          () => mockConsole.write('  '),
          () => mockConsole.setForegroundColor(ConsoleColor.blue),
          () => mockConsole.write('1'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.write(': command 1\n'),
          () => mockConsole.write('  '),
          () => mockConsole.setForegroundColor(ConsoleColor.blue),
          () => mockConsole.write('2'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.write(': command 2\n'),
          () => mockConsole.write('> '),
          () => mockConsole.setTextStyle(blink: true),
          () => mockConsole.readKey(),
          () => mockConsole.setTextStyle(),
          () => mockConsole.setForegroundColor(ConsoleColor.red),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine('Invalid option: 3!'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.writeLine('What do you want to do?'),
          () => mockConsole.write('  '),
          () => mockConsole.setForegroundColor(ConsoleColor.blue),
          () => mockConsole.write('1'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.write(': command 1\n'),
          () => mockConsole.write('  '),
          () => mockConsole.setForegroundColor(ConsoleColor.blue),
          () => mockConsole.write('2'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.write(': command 2\n'),
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
