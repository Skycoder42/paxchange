// ignore_for_file: unnecessary_lambdas for tests

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/pacman_command.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:test/test.dart';

class MockPacman extends Mock implements Pacman {}

class MockConsole extends Mock implements Console {}

class MockPrompter extends Mock implements Prompter {}

void main() {
  setUpAll(() {
    registerFallbackValue(InstallReason.asExplicit);
  });

  const testPackageName = 'test-package';

  final mockPacman = MockPacman();
  final mockConsole = MockConsole();
  final mockPrompter = MockPrompter();

  setUp(() {
    reset(mockPacman);
    reset(mockConsole);
    reset(mockPrompter);
  });

  group('$InstallCommand', () {
    late InstallCommand sut;

    setUp(() {
      sut = InstallCommand(
        mockConsole,
        mockPacman,
        mockPrompter,
        testPackageName,
      );
    });

    test('uses correct key', () {
      expect(sut.key, 'i');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('runs pacman and returns success', () async {
        when(() => mockPacman.installPackages(any())).thenReturnAsync(0);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.installPackages(const [testPackageName]),
        ]);

        expect(result, PromptResult.succeeded);
      });

      test('runs pacman and prints error message if pacman fails', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.installPackages(any())).thenReturnAsync(10);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.installPackages(const [testPackageName]),
          () => mockPrompter.writeError(
            any(
              that: allOf(
                contains('install'),
                contains(testPackageName),
                contains('exit code 10'),
              ),
            ),
          ),
        ]);

        expect(result, PromptResult.repeat);
      });
    });
  });

  group('$RemoveCommand (normal)', () {
    late RemoveCommand sut;

    setUp(() {
      sut = RemoveCommand(
        mockConsole,
        mockPacman,
        mockPrompter,
        testPackageName,
      );
    });

    test('uses correct key', () {
      expect(sut.key, 'u');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('runs pacman and returns success', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.removePackage(any())).thenReturnAsync(0);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.removePackage(testPackageName),
        ]);

        expect(result, PromptResult.succeeded);
      });

      test('runs pacman and prints error message if pacman fails', () async {
        const testPackageName = 'test-package';

        when(() => mockPacman.removePackage(any())).thenReturnAsync(10);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.removePackage(testPackageName),
          () => mockPrompter.writeError(
            any(
              that: allOf(
                contains('uninstall'),
                contains(testPackageName),
                contains('exit code 10'),
              ),
            ),
          ),
        ]);

        expect(result, PromptResult.repeat);
      });
    });
  });

  group('$RemoveCommand (recursive)', () {
    late RemoveCommand sut;

    setUp(() {
      sut = RemoveCommand(
        mockConsole,
        mockPacman,
        mockPrompter,
        testPackageName,
        recursive: true,
      );
    });

    test('uses correct key', () {
      expect(sut.key, 'r');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('runs pacman and returns success', () async {
        const testPackageName = 'test-package';

        when(
          () => mockPacman.removePackage(
            any(),
            recursive: any(named: 'recursive'),
          ),
        ).thenReturnAsync(0);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.removePackage(testPackageName, recursive: true),
        ]);

        expect(result, PromptResult.succeeded);
      });

      test('runs pacman and prints error message if pacman fails', () async {
        const testPackageName = 'test-package';

        when(
          () => mockPacman.removePackage(
            any(),
            recursive: any(named: 'recursive'),
          ),
        ).thenReturnAsync(10);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.removePackage(testPackageName, recursive: true),
          () => mockPrompter.writeError(
            any(
              that: allOf(
                contains('uninstall'),
                contains(testPackageName),
                contains('exit code 10'),
              ),
            ),
          ),
        ]);

        expect(result, PromptResult.repeat);
      });
    });
  });

  group('$MarkImplicitlyInstalledCommand', () {
    late MarkImplicitlyInstalledCommand sut;

    setUp(() {
      sut = MarkImplicitlyInstalledCommand(
        mockConsole,
        mockPacman,
        mockPrompter,
        testPackageName,
      );
    });

    test('uses correct key', () {
      expect(sut.key, 'm');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('runs pacman and returns success', () async {
        const testPackageName = 'test-package';

        when(
          () => mockPacman.changePackageInstallReason(any(), any()),
        ).thenReturnAsync(0);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.changePackageInstallReason(
            testPackageName,
            InstallReason.asDeps,
          ),
        ]);

        expect(result, PromptResult.succeeded);
      });

      test('runs pacman and prints error message if pacman fails', () async {
        const testPackageName = 'test-package';

        when(
          () => mockPacman.changePackageInstallReason(any(), any()),
        ).thenReturnAsync(10);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.changePackageInstallReason(
            testPackageName,
            InstallReason.asDeps,
          ),
          () => mockPrompter.writeError(
            any(
              that: allOf(
                contains('mark'),
                contains(testPackageName),
                contains('exit code 10'),
              ),
            ),
          ),
        ]);

        expect(result, PromptResult.repeat);
      });
    });
  });

  group('$MarkExplicitlyInstalledCommand', () {
    late MarkExplicitlyInstalledCommand sut;

    setUp(() {
      sut = MarkExplicitlyInstalledCommand(
        mockConsole,
        mockPacman,
        mockPrompter,
        testPackageName,
      );
    });

    test('uses correct key', () {
      expect(sut.key, 'm');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('runs pacman and returns success', () async {
        const testPackageName = 'test-package';

        when(
          () => mockPacman.changePackageInstallReason(any(), any()),
        ).thenReturnAsync(0);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.changePackageInstallReason(
            testPackageName,
            InstallReason.asExplicit,
          ),
        ]);

        expect(result, PromptResult.succeeded);
      });

      test('runs pacman and prints error message if pacman fails', () async {
        const testPackageName = 'test-package';

        when(
          () => mockPacman.changePackageInstallReason(any(), any()),
        ).thenReturnAsync(10);

        final result = await sut();

        verifyInOrder([
          () => mockConsole.clearScreen(),
          () => mockPacman.changePackageInstallReason(
            testPackageName,
            InstallReason.asExplicit,
          ),
          () => mockPrompter.writeError(
            any(
              that: allOf(
                contains('mark'),
                contains(testPackageName),
                contains('exit code 10'),
              ),
            ),
          ),
        ]);

        expect(result, PromptResult.repeat);
      });
    });
  });
}
