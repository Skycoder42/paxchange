// ignore_for_file: unnecessary_lambdas for tests

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

final class TestPromptCommand extends PromptCommand {
  final _call = MockCallable0<PromptResult>();

  @override
  final String key;

  @override
  final String description;

  TestPromptCommand(
    super.console,
    super.packageName,
    this.key,
    this.description,
  );

  @override
  PromptResult call() => _call();

  void resetCall() => reset(_call);
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockConsole());
  });

  group('$Prompter', () {
    final mockConsole = MockConsole();

    late Prompter sut;

    setUp(() {
      reset(mockConsole);

      sut = Prompter(mockConsole);
    });

    test('writeError writes error line', () {
      const message = 'error-message';

      sut.writeError(message);

      verifyInOrder([
        () => mockConsole.setForegroundColor(ConsoleColor.red),
        () => mockConsole.writeLine(),
        () => mockConsole.writeLine(message),
        () => mockConsole.resetColorAttributes(),
      ]);
    });

    test('writeTitle writes a title with bold segments', () {
      const prefix = 'prefix ';
      const suffix = ' suffix';
      const package = 'test-package';
      const color = ConsoleColor.magenta;

      sut.writeTitle(message: '$prefix**$package**$suffix', color: color);

      verifyInOrder([
        () => mockConsole.resetColorAttributes(),
        () => mockConsole.clearScreen(),
        () => mockConsole.setForegroundColor(color),
        () => mockConsole.write(prefix),
        () => mockConsole.setTextStyle(bold: true),
        () => mockConsole.write(package),
        () => mockConsole.setTextStyle(),
        () => mockConsole.setForegroundColor(color),
        () => mockConsole.write(suffix),
        () => mockConsole.setTextStyle(bold: true),
        () => mockConsole.setTextStyle(),
        () => mockConsole.resetColorAttributes(),
        () => mockConsole.writeLine(),
      ]);
      verifyNoMoreInteractions(mockConsole);
    });

    group('promptOption', () {
      const testDescription = 'test-description';
      const testOptions = {'1': 'option 1', '2': 'option 2'};

      test(
        'writes a prompt with all options and returns result of selected',
        () {
          when(() => mockConsole.readKey()).thenReturn(Key.printable('1'));

          final result = sut.promptOption(
            description: testDescription,
            options: testOptions,
          );

          verifyInOrder([
            () => mockConsole.writeLine(testDescription),
            for (final MapEntry(:key, :value) in testOptions.entries) ...[
              () => mockConsole.write('  '),
              () => mockConsole.setForegroundColor(ConsoleColor.blue),
              () => mockConsole.write(key),
              () => mockConsole.resetColorAttributes(),
              () => mockConsole.write(': $value\n'),
            ],
            () => mockConsole.write('> '),
            () => mockConsole.setTextStyle(blink: true),
            () => mockConsole.readKey(),
            () => mockConsole.setTextStyle(),
            () => mockConsole.setForegroundColor(ConsoleColor.green),
            () => mockConsole.write('1'),
            () => mockConsole.resetColorAttributes(),
            () => mockConsole.writeLine(),
          ]);
          verifyNoMoreInteractions(mockConsole);

          expect(result, '1');
        },
      );

      test('writes a looping prompt for invalid inputs', () {
        var keyCtr = 3;
        when(
          () => mockConsole.readKey(),
        ).thenAnswer((i) => Key.printable('${keyCtr--}'));

        final result = sut.promptOption(
          description: testDescription,
          options: testOptions,
        );

        verifyInOrder([
          () => mockConsole.writeLine(testDescription),
          for (final MapEntry(:key, :value) in testOptions.entries) ...[
            () => mockConsole.write('  '),
            () => mockConsole.setForegroundColor(ConsoleColor.blue),
            () => mockConsole.write(key),
            () => mockConsole.resetColorAttributes(),
            () => mockConsole.write(': $value\n'),
          ],
          () => mockConsole.write('> '),
          () => mockConsole.setTextStyle(blink: true),
          () => mockConsole.readKey(),
          () => mockConsole.setTextStyle(),
          () => mockConsole.setForegroundColor(ConsoleColor.red),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine('Invalid option: 3!'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.writeLine(testDescription),
          for (final MapEntry(:key, :value) in testOptions.entries) ...[
            () => mockConsole.write('  '),
            () => mockConsole.setForegroundColor(ConsoleColor.blue),
            () => mockConsole.write(key),
            () => mockConsole.resetColorAttributes(),
            () => mockConsole.write(': $value\n'),
          ],
          () => mockConsole.write('> '),
          () => mockConsole.setTextStyle(blink: true),
          () => mockConsole.readKey(),
          () => mockConsole.setTextStyle(),
          () => mockConsole.setForegroundColor(ConsoleColor.green),
          () => mockConsole.write('2'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.writeLine(),
        ]);
        verifyNoMoreInteractions(mockConsole);

        expect(result, '2');
      });
    });

    group('promptCommand', () {
      const testPackageName = 'test-package';
      final cmd1 = TestPromptCommand(
        mockConsole,
        testPackageName,
        '1',
        'command 1',
      );
      final cmd2 = TestPromptCommand(
        mockConsole,
        testPackageName,
        '2',
        'command 2',
      );

      setUp(() {
        cmd1.resetCall();
        cmd2.resetCall();

        when(() => cmd1.call()).thenReturn(PromptResult.succeeded);
        when(() => cmd2.call()).thenReturn(PromptResult.repeat);
      });

      test(
        'writes a prompt with all options and returns result of selected',
        () async {
          when(() => mockConsole.readKey()).thenReturn(Key.printable('1'));

          final result = await sut.promptCommand([cmd1, cmd2]);

          verifyInOrder([
            () => mockConsole.writeLine('What do you want to do?'),
            for (final cmd in [cmd1, cmd2]) ...[
              () => mockConsole.write('  '),
              () => mockConsole.setForegroundColor(ConsoleColor.blue),
              () => mockConsole.write(cmd.key),
              () => mockConsole.resetColorAttributes(),
              () => mockConsole.write(': ${cmd.description}\n'),
            ],
            () => mockConsole.write('> '),
            () => mockConsole.setTextStyle(blink: true),
            () => mockConsole.readKey(),
            () => mockConsole.setTextStyle(),
            () => mockConsole.setForegroundColor(ConsoleColor.green),
            () => mockConsole.write('1'),
            () => mockConsole.resetColorAttributes(),
            () => mockConsole.writeLine(),
            () => cmd1.call(),
          ]);
          // verifyNoMoreInteractions(mockConsole);
          expect(result, PromptResult.succeeded);
        },
      );

      test('writes a looping prompt if output is repeat', () async {
        var keyCtr = 2;
        when(
          () => mockConsole.readKey(),
        ).thenAnswer((i) => Key.printable('${keyCtr--}'));

        final result = await sut.promptCommand([cmd1, cmd2]);

        verifyInOrder([
          // cmd 2
          () => mockConsole.writeLine('What do you want to do?'),
          for (final cmd in [cmd1, cmd2]) ...[
            () => mockConsole.write('  '),
            () => mockConsole.setForegroundColor(ConsoleColor.blue),
            () => mockConsole.write(cmd.key),
            () => mockConsole.resetColorAttributes(),
            () => mockConsole.write(': ${cmd.description}\n'),
          ],
          () => mockConsole.write('> '),
          () => mockConsole.setTextStyle(blink: true),
          () => mockConsole.readKey(),
          () => mockConsole.setTextStyle(),
          () => mockConsole.setForegroundColor(ConsoleColor.green),
          () => mockConsole.write('2'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.writeLine(),
          () => cmd2.call(),
          // cmd 1
          () => mockConsole.writeLine('What do you want to do?'),
          for (final cmd in [cmd1, cmd2]) ...[
            () => mockConsole.write('  '),
            () => mockConsole.setForegroundColor(ConsoleColor.blue),
            () => mockConsole.write(cmd.key),
            () => mockConsole.resetColorAttributes(),
            () => mockConsole.write(': ${cmd.description}\n'),
          ],
          () => mockConsole.write('> '),
          () => mockConsole.setTextStyle(blink: true),
          () => mockConsole.readKey(),
          () => mockConsole.setTextStyle(),
          () => mockConsole.setForegroundColor(ConsoleColor.green),
          () => mockConsole.write('1'),
          () => mockConsole.resetColorAttributes(),
          () => mockConsole.writeLine(),
          () => cmd1.call(),
        ]);
        verifyNoMoreInteractions(mockConsole);
        expect(result, PromptResult.succeeded);
      });
    });
  });
}
