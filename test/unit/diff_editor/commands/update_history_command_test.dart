// ignore_for_file: unnecessary_lambdas

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/commands/update_history_command.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:test/test.dart';

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockConsole extends Mock implements Console {}

void main() {
  group('$AddHistoryCommand', () {
    const testMachineName = 'machine-name';
    const testIndex = 0;
    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockConsole = MockConsole();

    late AddHistoryCommand sut;

    setUp(() {
      reset(mockPackageFileAdapter);
      reset(mockConsole);

      when(() => mockConsole.readKey()).thenReturn(Key.printable(' '));

      sut = AddHistoryCommand(
        mockPackageFileAdapter,
        testIndex,
        testMachineName,
      );
    });

    test('uses correct key', () {
      expect(sut.key, testIndex.toString());
      expect(sut.description, contains(testMachineName));
    });

    test('call adds package to history', () async {
      when(() => mockPackageFileAdapter.addToPackageFile(any(), any()))
          .thenReturnAsync(null);

      const testPackageName = 'test-package';
      final result = await sut(mockConsole, testPackageName);

      verifyInOrder([
        () => mockConsole.writeLine(),
        () => mockConsole.writeLine(
              'Adding $testPackageName for $testMachineName...',
            ),
        () => mockPackageFileAdapter.addToPackageFile(
              testMachineName,
              testPackageName,
            ),
        () => mockConsole.writeLine(any()),
        () => mockConsole.readKey(),
      ]);
      expect(result, PromptResult.succeeded);
    });

    test('generate creates list of commands', () {
      const machineHierarchy = ['file1', 'file2', 'file3'];

      final commands = AddHistoryCommand.generate(
        mockPackageFileAdapter,
        machineHierarchy,
      );

      expect(commands, hasLength(machineHierarchy.length));
      for (var i = 0; i < machineHierarchy.length; ++i) {
        final command = commands[i];
        expect(command.key, i.toString());
        expect(command.description, contains(machineHierarchy[i]));
      }
    });
  });

  group('$RemoveHistoryCommand', () {
    const testMachineName = 'machine-name';
    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockConsole = MockConsole();

    late RemoveHistoryCommand sut;

    setUp(() {
      reset(mockPackageFileAdapter);
      reset(mockConsole);

      when(() => mockConsole.readKey()).thenReturn(Key.printable(' '));

      sut = RemoveHistoryCommand(
        mockPackageFileAdapter,
        testMachineName,
      );
    });

    test('uses correct key', () {
      expect(sut.key, 'd');
      expect(sut.description, isNotEmpty);
    });

    test('call removes package from history', () async {
      when(() => mockPackageFileAdapter.removeFromPackageFile(any(), any()))
          .thenReturnAsync(true);

      const testPackageName = 'test-package';
      final result = await sut(mockConsole, testPackageName);

      verifyInOrder([
        () => mockConsole.writeLine(),
        () => mockConsole.writeLine(
              'Removing $testPackageName for $testMachineName...',
            ),
        () => mockPackageFileAdapter.removeFromPackageFile(
              testMachineName,
              testPackageName,
            ),
        () => mockConsole.writeLine(any()),
        () => mockConsole.readKey(),
      ]);
      expect(result, PromptResult.succeeded);
    });
  });
}
