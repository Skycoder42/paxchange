// ignore_for_file: unnecessary_lambdas

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/commands/update_history_command.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:test/test.dart';

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockConsole extends Mock implements Console {}

class MockPrompter extends Mock implements Prompter {}

void main() {
  final mockPackageFileAdapter = MockPackageFileAdapter();
  final mockConsole = MockConsole();
  final mockPrompter = MockPrompter();

  setUp(() {
    reset(mockPackageFileAdapter);
    reset(mockConsole);
    reset(mockPrompter);
  });

  group('$AddHistoryCommand', () {
    const testMachineName = 'machine-name';
    const testIndex = 0;

    late AddHistoryCommand sut;

    setUp(() {
      sut = AddHistoryCommand(
        mockConsole,
        mockPackageFileAdapter,
        mockPrompter,
        testIndex,
        testMachineName,
      );
    });

    test('uses correct key', () {
      expect(sut.key, testIndex.toString());
      expect(sut.description, contains(testMachineName));
    });

    group('call', () {
      test('adds package to history', () async {
        when(
          () => mockPackageFileAdapter.addToPackageFile(any(), any()),
        ).thenReturnAsync(null);

        const testPackageName = 'test-package';
        final result = await sut(testPackageName);

        verifyInOrder([
          () => mockConsole.writeLine(
            'Adding $testPackageName for $testMachineName...',
          ),
          () => mockPackageFileAdapter.addToPackageFile(
            testMachineName,
            testPackageName,
          ),
        ]);
        expect(result, PromptResult.succeeded);
      });
    });

    test('generate creates list of commands', () {
      const machineHierarchy = ['file1', 'file2', 'file3'];

      final commands = AddHistoryCommand.generate(
        mockConsole,
        mockPackageFileAdapter,
        mockPrompter,
        machineHierarchy,
      );

      expect(commands, hasLength(machineHierarchy.length));
      for (var i = 1; i <= machineHierarchy.length; ++i) {
        final command = commands[i - 1];
        final machineIndex = machineHierarchy.length - i;
        expect(command.key, i.toString());
        expect(command.description, contains(machineHierarchy[machineIndex]));
      }
    });
  });

  group('$RemoveHistoryCommand', () {
    const testMachineName = 'machine-name';

    late RemoveHistoryCommand sut;

    setUp(() {
      sut = RemoveHistoryCommand(
        mockConsole,
        mockPackageFileAdapter,
        mockPrompter,
        testMachineName,
      );
    });

    test('uses correct key', () {
      expect(sut.key, 'd');
      expect(sut.description, isNotEmpty);
    });

    group('call', () {
      test('removes package from history', () async {
        when(
          () => mockPackageFileAdapter.removeFromPackageFile(any(), any()),
        ).thenReturnAsync(true);

        const testPackageName = 'test-package';
        final result = await sut(testPackageName);

        verifyInOrder([
          () => mockConsole.writeLine(
            'Removing $testPackageName for $testMachineName...',
          ),
          () => mockPackageFileAdapter.removeFromPackageFile(
            testMachineName,
            testPackageName,
          ),
        ]);
        expect(result, PromptResult.succeeded);
      });

      test(
        'prints error and returns failure if package was not removed',
        () async {
          when(
            () => mockPackageFileAdapter.removeFromPackageFile(any(), any()),
          ).thenReturnAsync(false);

          const testPackageName = 'test-package';
          final result = await sut(testPackageName);

          verifyInOrder([
            () => mockConsole.writeLine(
              'Removing $testPackageName for $testMachineName...',
            ),
            () => mockPackageFileAdapter.removeFromPackageFile(
              testMachineName,
              testPackageName,
            ),
            () => mockPrompter.writeError(
              any(
                that: allOf(
                  contains(testPackageName),
                  contains(testMachineName),
                ),
              ),
            ),
          ]);
          expect(result, PromptResult.failed);
        },
      );
    });
  });
}
