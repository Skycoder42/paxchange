// ignore_for_file: unnecessary_lambdas

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
  FutureOr<PromptResult> call(Console console, String packageName) =>
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
  });
}
