// ignore_for_file: unnecessary_lambdas

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/pacman_command.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:test/test.dart';

class MockPacman extends Mock implements Pacman {}

class MockConsole extends Mock implements Console {}

void main() {
  setUpAll(() {
    registerFallbackValue(InstallReason.asExplicit);
  });

  group('$InstallCommand', () {
    final mockPacman = MockPacman();
    final mockConsole = MockConsole();

    late InstallCommand sut;

    setUp(() {
      reset(mockPacman);
      reset(mockConsole);

      when(() => mockConsole.readKey()).thenReturn(Key.printable(' '));

      sut = InstallCommand(mockPacman);
    });

    test('uses correct key', () {
      expect(sut.key, 'i');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('runs pacman and prints success message', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.installPackages(any())).thenReturnAsync(0);

        final result = await sut(mockConsole, testPackageName);

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.installPackages(const [testPackageName]),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine(
                any(
                  that: allOf(
                    contains('install'),
                    contains(testPackageName),
                  ),
                ),
              ),
          () => mockConsole.readKey(),
        ]);

        expect(result, PromptResult.succeeded);
      });

      test('runs pacman and prints error message if pacman fails', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.installPackages(any())).thenReturnAsync(10);

        final result = await sut(mockConsole, testPackageName);

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.installPackages(const [testPackageName]),
          () => mockConsole.setForegroundColor(ConsoleColor.red),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine(
                any(
                  that: allOf(
                    contains('install'),
                    contains(testPackageName),
                    contains('exit code 10'),
                  ),
                ),
              ),
          () => mockConsole.resetColorAttributes(),
        ]);

        expect(result, PromptResult.failed);
      });
    });
  });

  group('$RemoveCommand', () {
    final mockPacman = MockPacman();
    final mockConsole = MockConsole();

    late RemoveCommand sut;

    setUp(() {
      reset(mockPacman);
      reset(mockConsole);

      when(() => mockConsole.readKey()).thenReturn(Key.printable(' '));

      sut = RemoveCommand(mockPacman);
    });

    test('uses correct key', () {
      expect(sut.key, 'r');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('runs pacman and prints success message', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.removePackage(any())).thenReturnAsync(0);

        final result = await sut(mockConsole, testPackageName);

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.removePackage(testPackageName),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine(
                any(
                  that: allOf(
                    contains('uninstall'),
                    contains(testPackageName),
                  ),
                ),
              ),
          () => mockConsole.readKey(),
        ]);

        expect(result, PromptResult.succeeded);
      });

      test('runs pacman and prints error message if pacman fails', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.removePackage(any())).thenReturnAsync(10);

        final result = await sut(mockConsole, testPackageName);

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.removePackage(testPackageName),
          () => mockConsole.setForegroundColor(ConsoleColor.red),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine(
                any(
                  that: allOf(
                    contains('uninstall'),
                    contains(testPackageName),
                    contains('exit code 10'),
                  ),
                ),
              ),
          () => mockConsole.resetColorAttributes(),
        ]);

        expect(result, PromptResult.failed);
      });
    });
  });

  group('$MarkImplicitlyInstalledCommand', () {
    final mockPacman = MockPacman();
    final mockConsole = MockConsole();

    late MarkImplicitlyInstalledCommand sut;

    setUp(() {
      reset(mockPacman);
      reset(mockConsole);

      when(() => mockConsole.readKey()).thenReturn(Key.printable(' '));

      sut = MarkImplicitlyInstalledCommand(mockPacman);
    });

    test('uses correct key', () {
      expect(sut.key, 'm');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('runs pacman and prints success message', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.changePackageInstallReason(any(), any()))
            .thenReturnAsync(0);

        final result = await sut(mockConsole, testPackageName);

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.changePackageInstallReason(
                testPackageName,
                InstallReason.asDeps,
              ),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine(
                any(
                  that: allOf(
                    contains('mark'),
                    contains(testPackageName),
                  ),
                ),
              ),
          () => mockConsole.readKey(),
        ]);

        expect(result, PromptResult.succeeded);
      });

      test('runs pacman and prints error message if pacman fails', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.changePackageInstallReason(any(), any()))
            .thenReturnAsync(10);

        final result = await sut(mockConsole, testPackageName);

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.changePackageInstallReason(
                testPackageName,
                InstallReason.asDeps,
              ),
          () => mockConsole.setForegroundColor(ConsoleColor.red),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine(
                any(
                  that: allOf(
                    contains('mark'),
                    contains(testPackageName),
                    contains('exit code 10'),
                  ),
                ),
              ),
          () => mockConsole.resetColorAttributes(),
        ]);

        expect(result, PromptResult.failed);
      });
    });
  });

  group('$MarkExplicitlyInstalledCommand', () {
    final mockPacman = MockPacman();
    final mockConsole = MockConsole();

    late MarkExplicitlyInstalledCommand sut;

    setUp(() {
      reset(mockPacman);
      reset(mockConsole);

      when(() => mockConsole.readKey()).thenReturn(Key.printable(' '));

      sut = MarkExplicitlyInstalledCommand(mockPacman);
    });

    test('uses correct key', () {
      expect(sut.key, 'm');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('runs pacman and prints success message', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.changePackageInstallReason(any(), any()))
            .thenReturnAsync(0);

        final result = await sut(mockConsole, testPackageName);

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.changePackageInstallReason(
                testPackageName,
                InstallReason.asExplicit,
              ),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine(
                any(
                  that: allOf(
                    contains('mark'),
                    contains(testPackageName),
                  ),
                ),
              ),
          () => mockConsole.readKey(),
        ]);

        expect(result, PromptResult.succeeded);
      });

      test('runs pacman and prints error message if pacman fails', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.changePackageInstallReason(any(), any()))
            .thenReturnAsync(10);

        final result = await sut(mockConsole, testPackageName);

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.changePackageInstallReason(
                testPackageName,
                InstallReason.asExplicit,
              ),
          () => mockConsole.setForegroundColor(ConsoleColor.red),
          () => mockConsole.writeLine(),
          () => mockConsole.writeLine(
                any(
                  that: allOf(
                    contains('mark'),
                    contains(testPackageName),
                    contains('exit code 10'),
                  ),
                ),
              ),
          () => mockConsole.resetColorAttributes(),
        ]);

        expect(result, PromptResult.failed);
      });
    });
  });
}
