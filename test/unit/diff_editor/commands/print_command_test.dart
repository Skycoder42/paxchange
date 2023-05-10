// ignore_for_file: unnecessary_lambdas

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/print_command.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:test/test.dart';

class MockPacman extends Mock implements Pacman {}

class MockConsole extends Mock implements Console {}

void main() {
  group('$PrintCommand', () {
    final mockPacman = MockPacman();
    final mockConsole = MockConsole();

    setUp(() {
      reset(mockPacman);
      reset(mockConsole);

      when(() => mockConsole.readKey()).thenReturn(Key.printable(' '));
    });

    test('local prints local package status', () async {
      const testPackageName = 'test-package';
      const packageInfo = [
        'line-1',
        'line-2',
        'line-3',
      ];
      when(() => mockPacman.queryInstalledPackage(any()))
          .thenStream(Stream.fromIterable(packageInfo));

      final sut = PrintCommand.local(mockPacman);

      expect(sut.key, 'p');
      expect(sut.description, isNotEmpty);
      expect(sut.printTarget, PrintTarget.local);

      final result = await sut(mockConsole, testPackageName);

      verifyInOrder([
        () => mockPacman.queryInstalledPackage(testPackageName),
        () => mockConsole.clearScreen(),
        ...packageInfo.map((line) => () => mockConsole.writeLine(line)),
        () => mockConsole.writeLine(),
      ]);
      expect(result, PromptResult.repeat);
    });

    test('remote prints remote package status', () async {
      const testPackageName = 'test-package';
      const packageInfo = [
        'line-1',
        'line-2',
        'line-3',
      ];
      when(() => mockPacman.queryUninstalledPackage(any()))
          .thenStream(Stream.fromIterable(packageInfo));

      final sut = PrintCommand.remote(mockPacman);

      expect(sut.key, 'p');
      expect(sut.description, isNotEmpty);
      expect(sut.printTarget, PrintTarget.remote);

      final result = await sut(mockConsole, testPackageName);

      verifyInOrder([
        () => mockPacman.queryUninstalledPackage(testPackageName),
        () => mockConsole.clearScreen(),
        ...packageInfo.map((line) => () => mockConsole.writeLine(line)),
        () => mockConsole.writeLine(),
      ]);
      expect(result, PromptResult.repeat);
    });
  });
}
