import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/add_group_command.dart';
import 'package:paxchange/src/diff_editor/commands/expand_group_command.dart';
import 'package:paxchange/src/diff_editor/commands/pacman_command.dart';
import 'package:paxchange/src/diff_editor/commands/print_command.dart';
import 'package:paxchange/src/diff_editor/commands/update_history_command.dart';
import 'package:paxchange/src/diff_editor/editors/diff_editor.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/diff_entry.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/storage/diff_file_adapter.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:paxchange/src/storage/package_file_hierarchy.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

class MockPrompter extends Mock implements Prompter {}

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockDiffFileAdapter extends Mock implements DiffFileAdapter {}

class MockPacman extends Mock implements Pacman {}

void main() {
  group('$DiffEditor', () {
    const testMachineName = 'test-machine';
    const testPackageFiles = [testMachineName, 'file2', 'file3'];
    final testHierarchy = PackageFileHierarchy(
      packageFiles: testPackageFiles.toSet(),
      groupsByPackages: {},
    );
    const testPackage = 'test-package';

    final mockConsole = MockConsole();
    final mockPrompter = MockPrompter();
    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockDiffFileAdapter = MockDiffFileAdapter();
    final mockPacman = MockPacman();

    late DiffEditor sut;

    setUp(() {
      reset(mockConsole);
      reset(mockPrompter);
      reset(mockPackageFileAdapter);
      reset(mockDiffFileAdapter);
      reset(mockPacman);

      sut = DiffEditor(
        mockConsole,
        mockPrompter,
        mockPackageFileAdapter,
        mockDiffFileAdapter,
        mockPacman,
      );
    });

    test('loadTargets returns diff entries', () async {
      const testDiff = [
        DiffEntry.added('package-1'),
        DiffEntry.removed('package-2'),
      ];
      when(
        () => mockDiffFileAdapter.loadPackageDiff(any()),
      ).thenStream(Stream.fromIterable(testDiff));

      final result = sut.loadTargets(testMachineName, testHierarchy);

      await expectLater(result, emitsInOrder([...testDiff, emitsDone]));

      verify(() => mockDiffFileAdapter.loadPackageDiff(testMachineName));
    });

    group('buildCommands', () {
      test('writes title and builds commands for added diff entry', () async {
        final result = sut.buildCommands(
          testMachineName,
          testHierarchy,
          const DiffEntry.added(testPackage),
        );

        await expectLater(
          result,
          emitsInOrder([
            isA<PrintCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((c) => c.printTarget, 'printTarget', PrintTarget.local),
            isA<RemoveCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((m) => m.recursive, 'recursive', isFalse),
            isA<RemoveCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((m) => m.recursive, 'recursive', isTrue),
            isA<MarkImplicitlyInstalledCommand>().having(
              (m) => m.packageName,
              'packageName',
              testPackage,
            ),
            isA<AddHistoryCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((c) => c.index, 'index', 1)
                .having((c) => c.machineName, 'index', testPackageFiles[2]),
            isA<AddHistoryCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((c) => c.index, 'index', 2)
                .having((c) => c.machineName, 'index', testPackageFiles[1]),
            isA<AddHistoryCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((c) => c.index, 'index', 3)
                .having((c) => c.machineName, 'index', testPackageFiles[0]),
            isA<AddGroupCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having(
                  (m) => m.machineHierarchy,
                  'machineHierarchy',
                  testPackageFiles,
                ),
            emitsDone,
          ]),
        );

        verify(
          () => mockPrompter.writeTitle(
            message:
                'Found installed package **$testPackage** '
                'that is not in the history yet!',
            color: ConsoleColor.green,
          ),
        ).called(1);
      });

      test('writes title and builds commands for '
          'removed diff entry with removed package', () async {
        when(
          () => mockPacman.checkIfPackageIsInstalled(any()),
        ).thenReturnAsync(false);

        final result = sut.buildCommands(
          testMachineName,
          testHierarchy,
          const DiffEntry.removed(testPackage),
        );

        await expectLater(
          result,
          emitsInOrder([
            isA<PrintCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having(
                  (c) => c.printTarget,
                  'printTarget',
                  PrintTarget.remote,
                ),
            isA<InstallCommand>().having(
              (m) => m.packageName,
              'packageName',
              testPackage,
            ),
            isA<RemoveHistoryCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((c) => c.machineName, 'index', testMachineName),
            emitsDone,
          ]),
        );

        verify(
          () => mockPacman.checkIfPackageIsInstalled(testPackage),
        ).called(1);
        verify(
          () => mockPrompter.writeTitle(
            message:
                'Found uninstalled package **$testPackage** '
                'that is in the history!',
            color: ConsoleColor.red,
          ),
        ).called(1);
      });

      test('writes title and builds commands for removed diff entry '
          'with implicitly installed package', () async {
        when(
          () => mockPacman.checkIfPackageIsInstalled(any()),
        ).thenReturnAsync(true);

        final result = sut.buildCommands(
          testMachineName,
          testHierarchy,
          const DiffEntry.removed(testPackage),
        );

        await expectLater(
          result,
          emitsInOrder([
            isA<PrintCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((c) => c.printTarget, 'printTarget', PrintTarget.local),
            isA<MarkExplicitlyInstalledCommand>().having(
              (m) => m.packageName,
              'packageName',
              testPackage,
            ),
            isA<RemoveHistoryCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((c) => c.machineName, 'index', testMachineName),
            emitsDone,
          ]),
        );

        verify(
          () => mockPacman.checkIfPackageIsInstalled(testPackage),
        ).called(1);
        verify(
          () => mockPrompter.writeTitle(
            message:
                'Found implicitly installed package '
                '**$testPackage** that is in the history!',
            color: ConsoleColor.yellow,
          ),
        ).called(1);
      });

      test('writes title and builds commands for removed diff entry '
          'with removed package that belongs to a group', () async {
        const testGroup = 'group-1';

        when(
          () => mockPacman.checkIfPackageIsInstalled(any()),
        ).thenReturnAsync(false);

        final result = sut.buildCommands(
          testMachineName,
          testHierarchy.copyWith(
            groupsByPackages: {
              testPackage: {testGroup, 'group-2'},
            },
          ),
          const DiffEntry.removed(testPackage),
        );

        await expectLater(
          result,
          emitsInOrder([
            isA<PrintCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having(
                  (c) => c.printTarget,
                  'printTarget',
                  PrintTarget.remote,
                ),
            isA<InstallCommand>().having(
              (m) => m.packageName,
              'packageName',
              testPackage,
            ),
            isA<ExpandGroupCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((m) => m.machineName, 'machineName', testMachineName)
                .having((m) => m.group, 'group', testGroup),
            emitsDone,
          ]),
        );

        verify(
          () => mockPacman.checkIfPackageIsInstalled(testPackage),
        ).called(1);
        verify(
          () => mockPrompter.writeTitle(
            message:
                'Found uninstalled package **$testPackage** '
                'belonging to group **$testGroup** '
                'that is in the history!',
            color: ConsoleColor.blue,
          ),
        ).called(1);
      });

      test('writes title and builds commands for removed diff entry with '
          'implicitly installed package that belongs to a group', () async {
        const testGroup = 'group-1';

        when(
          () => mockPacman.checkIfPackageIsInstalled(any()),
        ).thenReturnAsync(true);

        final result = sut.buildCommands(
          testMachineName,
          testHierarchy.copyWith(
            groupsByPackages: {
              testPackage: {testGroup, 'group-2'},
            },
          ),
          const DiffEntry.removed(testPackage),
        );

        await expectLater(
          result,
          emitsInOrder([
            isA<PrintCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((c) => c.printTarget, 'printTarget', PrintTarget.local),
            isA<MarkExplicitlyInstalledCommand>().having(
              (m) => m.packageName,
              'packageName',
              testPackage,
            ),
            isA<ExpandGroupCommand>()
                .having((m) => m.packageName, 'packageName', testPackage)
                .having((m) => m.machineName, 'machineName', testMachineName)
                .having((m) => m.group, 'group', testGroup),
            emitsDone,
          ]),
        );

        verify(
          () => mockPacman.checkIfPackageIsInstalled(testPackage),
        ).called(1);
        verify(
          () => mockPrompter.writeTitle(
            message:
                'Found implicitly installed package '
                '**$testPackage** belonging to group '
                '**$testGroup** that is in the history!',
            color: ConsoleColor.cyan,
          ),
        ).called(1);
      });
    });
  });
}
