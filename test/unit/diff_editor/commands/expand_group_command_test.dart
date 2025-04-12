// ignore_for_file: unnecessary_lambdas

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/expand_group_command.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockPacman extends Mock implements Pacman {}

class MockPrompter extends Mock implements Prompter {}

void main() {
  group('$ExpandGroupCommand', () {
    const testMachineName = 'testMachine';
    const testGroup = 'test-group';
    const testPackage = 'test-package';

    final mockConsole = MockConsole();
    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockPacman = MockPacman();
    final mockPrompter = MockPrompter();

    late ExpandGroupCommand sut;

    setUp(() {
      reset(mockConsole);
      reset(mockPackageFileAdapter);
      reset(mockPacman);
      reset(mockPrompter);

      sut = ExpandGroupCommand(
        mockConsole,
        mockPackageFileAdapter,
        mockPacman,
        mockPrompter,
        machineName: testMachineName,
        group: testGroup,
      );
    });

    test('uses correct key', () {
      expect(sut.key, 'e');
      expect(sut.description, contains(testGroup));
    });

    group('call', () {
      setUp(() {
        when(() => mockPacman.listInstalledPackagesForGroup(any())).thenStream(
          Stream.fromIterable(['package-1', testPackage, 'package-2']),
        );
      });

      test(
        'replaces group with its packages, excluding the current one',
        () async {
          when(
            () => mockPackageFileAdapter.removeFromPackageFile(
              any(),
              any(),
              isGroup: any(named: 'isGroup'),
              replacement: any(named: 'replacement'),
            ),
          ).thenReturnAsync(true);

          final result = await sut.call(testPackage);

          expect(result, PromptResult.succeededReload);
          verifyInOrder([
            () => mockPacman.listInstalledPackagesForGroup(testGroup),
            () => mockPackageFileAdapter.removeFromPackageFile(
              testMachineName,
              testGroup,
              isGroup: true,
              replacement: const ['package-1', 'package-2'],
            ),
          ]);
        },
      );

      test('reports error if the group could not be replaces', () async {
        when(
          () => mockPackageFileAdapter.removeFromPackageFile(
            any(),
            any(),
            isGroup: any(named: 'isGroup'),
            replacement: any(named: 'replacement'),
          ),
        ).thenReturnAsync(false);

        final result = await sut.call(testPackage);

        expect(result, PromptResult.failed);
        verifyInOrder([
          () => mockPacman.listInstalledPackagesForGroup(testGroup),
          () => mockPackageFileAdapter.removeFromPackageFile(
            testMachineName,
            testGroup,
            isGroup: true,
            replacement: const ['package-1', 'package-2'],
          ),
          () => mockPrompter.writeError(any(that: contains(testGroup))),
        ]);
      });
    });
  });
}
