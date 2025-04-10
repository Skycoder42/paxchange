// ignore_for_file: unnecessary_lambdas, discarded_futures

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/add_group_command.dart';
import 'package:paxchange/src/diff_editor/commands/pacman_command.dart';
import 'package:paxchange/src/diff_editor/commands/print_command.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/commands/quit_command.dart';
import 'package:paxchange/src/diff_editor/commands/skip_command.dart';
import 'package:paxchange/src/diff_editor/commands/update_history_command.dart';
import 'package:paxchange/src/diff_editor/diff_editor.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/diff_entry.dart';
import 'package:paxchange/src/package_sync.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/storage/diff_file_adapter.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:test/test.dart';

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockDiffFileAdapter extends Mock implements DiffFileAdapter {}

class MockPacman extends Mock implements Pacman {}

class MockPackageSync extends Mock implements PackageSync {}

class MockConsole extends Mock implements Console {}

class MockPrompter extends Mock implements Prompter {}

void main() {
  setUpAll(() {
    registerFallbackValue(Console());
    registerFallbackValue(ConsoleColor.black);
  });

  group('$DiffEditor', () {
    const testMachineName = 'test-machine';

    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockDiffFileAdapter = MockDiffFileAdapter();
    final mockPacman = MockPacman();
    final mockPackageSync = MockPackageSync();
    final mockConsole = MockConsole();
    final mockPrompter = MockPrompter();

    late DiffEditor sut;

    setUp(() {
      reset(mockPackageFileAdapter);
      reset(mockDiffFileAdapter);
      reset(mockPacman);
      reset(mockPackageSync);
      reset(mockConsole);
      reset(mockPrompter);

      when(
        () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
      ).thenReturnAsync(null);

      sut = DiffEditor(
        mockPackageFileAdapter,
        mockDiffFileAdapter,
        mockPacman,
        mockPackageSync,
        mockConsole,
        mockPrompter,
      );
    });

    group('run', () {
      setUp(() {
        when(() => mockConsole.hasTerminal).thenReturn(true);

        when(() => mockPackageSync.updatePackageDiff()).thenReturnAsync(0);
      });

      test('throws exception if console does not have a terminal', () {
        when(() => mockConsole.hasTerminal).thenReturn(false);

        expect(() => sut.run(testMachineName), throwsA(isException));

        verify(() => mockConsole.hasTerminal);
      });

      test('does nothing if no entries are present', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];

        when(
          () => mockPackageFileAdapter.loadPackageFileHierarchy(any()),
        ).thenStream(Stream.fromIterable(testHierarchy));
        when(
          () => mockDiffFileAdapter.loadPackageDiff(any()),
        ).thenStream(const Stream.empty());

        await sut.run(testMachineName);

        verifyInOrder([
          () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
        ]);
        verifyNoMoreInteractions(mockPackageSync);
      });

      test('presents added diff entry', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];
        const diffEntry = DiffEntry.added('package-1');

        when(
          () => mockPackageFileAdapter.loadPackageFileHierarchy(any()),
        ).thenStream(Stream.fromIterable(testHierarchy));
        when(
          () => mockDiffFileAdapter.loadPackageDiff(any()),
        ).thenStream(Stream.value(diffEntry));
        when(
          () => mockPrompter.promptCommand(
            packageName: any(named: 'packageName'),
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.succeeded);

        await sut.run(testMachineName);

        final captured =
            verifyInOrder([
                  () => mockPackageFileAdapter.ensurePackageFileExists(
                    testMachineName,
                  ),
                  () => mockPackageFileAdapter.loadPackageFileHierarchy(
                    testMachineName,
                  ),
                  () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
                  () => mockPrompter.writeTitle(
                    messagePrefix: 'Found installed package ',
                    messageHighlight: diffEntry.package,
                    messageSuffix: ' that is not in the history yet!',
                    color: ConsoleColor.green,
                  ),
                  () => mockPrompter.promptCommand(
                    packageName: diffEntry.package,
                    commands: captureAny(named: 'commands'),
                  ),
                  () => mockPackageSync.updatePackageDiff(),
                ]).captured[4].single
                as List<PromptCommand>;

        expect(captured, hasLength(9));
        expect(
          captured,
          contains(
            isA<PrintCommand>().having(
              (c) => c.printTarget,
              'printTarget',
              PrintTarget.local,
            ),
          ),
        );
        expect(captured, contains(isA<RemoveCommand>()));
        expect(captured, contains(isA<MarkImplicitlyInstalledCommand>()));
        expect(
          captured,
          contains(
            isA<AddHistoryCommand>()
                .having((c) => c.index, 'index', 0)
                .having((c) => c.machineName, 'index', testHierarchy[0]),
          ),
        );
        expect(
          captured,
          contains(
            isA<AddHistoryCommand>()
                .having((c) => c.index, 'index', 1)
                .having((c) => c.machineName, 'index', testHierarchy[1]),
          ),
        );
        expect(
          captured,
          contains(
            isA<AddHistoryCommand>()
                .having((c) => c.index, 'index', 2)
                .having((c) => c.machineName, 'index', testHierarchy[2]),
          ),
        );
        expect(
          captured,
          contains(
            isA<AddGroupCommand>().having(
              (m) => m.machineHierarchy,
              'machineHierarchy',
              testHierarchy,
            ),
          ),
        );
        expect(captured, contains(isA<SkipCommand>()));
        expect(captured, contains(isA<QuitCommand>()));
      });

      test('presents removed diff entry for removed package', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];
        const diffEntry = DiffEntry.removed('package-1');

        when(
          () => mockPackageFileAdapter.loadPackageFileHierarchy(any()),
        ).thenStream(Stream.fromIterable(testHierarchy));
        when(
          () => mockDiffFileAdapter.loadPackageDiff(any()),
        ).thenStream(Stream.value(diffEntry));
        when(
          () => mockPacman.checkIfPackageIsInstalled(any()),
        ).thenReturnAsync(false);
        when(
          () => mockPrompter.promptCommand(
            packageName: any(named: 'packageName'),
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.succeeded);

        await sut.run(testMachineName);

        final captured =
            verifyInOrder([
                  () => mockPackageFileAdapter.ensurePackageFileExists(
                    testMachineName,
                  ),
                  () => mockPackageFileAdapter.loadPackageFileHierarchy(
                    testMachineName,
                  ),
                  () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
                  () => mockPacman.checkIfPackageIsInstalled(diffEntry.package),
                  () => mockPrompter.writeTitle(
                    messagePrefix: 'Found uninstalled package ',
                    messageHighlight: diffEntry.package,
                    messageSuffix: ' that is in the history!',
                    color: ConsoleColor.red,
                  ),
                  () => mockPrompter.promptCommand(
                    packageName: diffEntry.package,
                    commands: captureAny(named: 'commands'),
                  ),
                  () => mockPackageSync.updatePackageDiff(),
                ]).captured[5].single
                as List<PromptCommand>;

        expect(captured, hasLength(5));
        expect(
          captured,
          contains(
            isA<PrintCommand>().having(
              (c) => c.printTarget,
              'printTarget',
              PrintTarget.remote,
            ),
          ),
        );
        expect(captured, contains(isA<InstallCommand>()));
        expect(
          captured,
          contains(
            isA<RemoveHistoryCommand>().having(
              (c) => c.machineName,
              'index',
              testMachineName,
            ),
          ),
        );
        expect(captured, contains(isA<SkipCommand>()));
        expect(captured, contains(isA<QuitCommand>()));
      });

      test(
        'presents removed diff entry for implicitly installed package',
        () async {
          const testHierarchy = [testMachineName, 'file2', 'file3'];
          const diffEntry = DiffEntry.removed('package-1');

          when(
            () => mockPackageFileAdapter.loadPackageFileHierarchy(any()),
          ).thenStream(Stream.fromIterable(testHierarchy));
          when(
            () => mockDiffFileAdapter.loadPackageDiff(any()),
          ).thenStream(Stream.value(diffEntry));
          when(
            () => mockPacman.checkIfPackageIsInstalled(any()),
          ).thenReturnAsync(true);
          when(
            () => mockPrompter.promptCommand(
              packageName: any(named: 'packageName'),
              commands: any(named: 'commands'),
            ),
          ).thenReturn(PromptResult.succeeded);

          await sut.run(testMachineName);

          final captured =
              verifyInOrder([
                    () => mockPackageFileAdapter.ensurePackageFileExists(
                      testMachineName,
                    ),
                    () => mockPackageFileAdapter.loadPackageFileHierarchy(
                      testMachineName,
                    ),
                    () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
                    () =>
                        mockPacman.checkIfPackageIsInstalled(diffEntry.package),
                    () => mockPrompter.writeTitle(
                      messagePrefix: 'Found implicitly installed package ',
                      messageHighlight: diffEntry.package,
                      messageSuffix: ' that is in the history!',
                      color: ConsoleColor.yellow,
                    ),
                    () => mockPrompter.promptCommand(
                      packageName: diffEntry.package,
                      commands: captureAny(named: 'commands'),
                    ),
                    () => mockPackageSync.updatePackageDiff(),
                  ]).captured[5].single
                  as List<PromptCommand>;

          expect(captured, hasLength(5));
          expect(
            captured,
            contains(
              isA<PrintCommand>().having(
                (c) => c.printTarget,
                'printTarget',
                PrintTarget.local,
              ),
            ),
          );
          expect(captured, contains(isA<MarkExplicitlyInstalledCommand>()));
          expect(
            captured,
            contains(
              isA<RemoveHistoryCommand>().having(
                (c) => c.machineName,
                'index',
                testMachineName,
              ),
            ),
          );
          expect(captured, contains(isA<SkipCommand>()));
          expect(captured, contains(isA<QuitCommand>()));
        },
      );

      test('aborts early if a command returns failed', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];
        const diffEntries = [
          DiffEntry.removed('package-1'),
          DiffEntry.added('package-2'),
          DiffEntry.added('package-3'),
        ];

        when(
          () => mockPackageFileAdapter.loadPackageFileHierarchy(any()),
        ).thenStream(Stream.fromIterable(testHierarchy));
        when(
          () => mockDiffFileAdapter.loadPackageDiff(any()),
        ).thenStream(Stream.fromIterable(diffEntries));
        when(
          () => mockPacman.checkIfPackageIsInstalled(any()),
        ).thenReturnAsync(false);
        when(
          () => mockPrompter.promptCommand(
            packageName: any(named: 'packageName'),
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.succeeded);
        when(
          () => mockPrompter.promptCommand(
            packageName: 'package-2',
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.failed);

        await sut.run(testMachineName);
        verifyInOrder([
          () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
          () => mockPrompter.writeTitle(
            messagePrefix: any(named: 'messagePrefix'),
            messageHighlight: diffEntries[0].package,
            messageSuffix: any(named: 'messageSuffix'),
            color: any(named: 'color'),
          ),
          () => mockPrompter.promptCommand(
            packageName: diffEntries[0].package,
            commands: any(named: 'commands'),
          ),
          () => mockPrompter.writeTitle(
            messagePrefix: any(named: 'messagePrefix'),
            messageHighlight: diffEntries[1].package,
            messageSuffix: any(named: 'messageSuffix'),
            color: any(named: 'color'),
          ),
          () => mockPrompter.promptCommand(
            packageName: diffEntries[1].package,
            commands: any(named: 'commands'),
          ),
          () => mockPackageSync.updatePackageDiff(),
        ]);
        verifyNoMoreInteractions(mockPrompter);
      });

      test('does not update diff if nothing was modified', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];
        const diffEntries = [
          DiffEntry.removed('package-1'),
          DiffEntry.added('package-2'),
          DiffEntry.added('package-3'),
        ];

        when(
          () => mockPackageFileAdapter.loadPackageFileHierarchy(any()),
        ).thenStream(Stream.fromIterable(testHierarchy));
        when(
          () => mockDiffFileAdapter.loadPackageDiff(any()),
        ).thenStream(Stream.fromIterable(diffEntries));
        when(
          () => mockPacman.checkIfPackageIsInstalled(any()),
        ).thenReturnAsync(false);
        when(
          () => mockPrompter.promptCommand(
            packageName: any(named: 'packageName'),
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.skipped);

        await sut.run(testMachineName);

        verifyNever(() => mockPackageSync.updatePackageDiff());
      });

      test(
        'updates diff and restart processing if command returns reload',
        () async {
          const testHierarchy = [testMachineName, 'file2', 'file3'];
          const diffEntries = [
            DiffEntry.removed('package-1'),
            DiffEntry.added('package-2'),
            DiffEntry.added('package-3'),
          ];

          when(
            () => mockPackageFileAdapter.loadPackageFileHierarchy(any()),
          ).thenStream(Stream.fromIterable(testHierarchy));
          when(
            () => mockDiffFileAdapter.loadPackageDiff(any()),
          ).thenStream(Stream.fromIterable(diffEntries));
          when(
            () => mockPacman.checkIfPackageIsInstalled(any()),
          ).thenReturnAsync(false);
          when(
            () => mockPrompter.promptCommand(
              packageName: any(named: 'packageName'),
              commands: any(named: 'commands'),
            ),
          ).thenReturn(PromptResult.succeeded);
          var didReload = false;
          when(
            () => mockPrompter.promptCommand(
              packageName: 'package-2',
              commands: any(named: 'commands'),
            ),
          ).thenAnswer((_) {
            if (didReload) {
              return PromptResult.succeeded;
            } else {
              didReload = true;
              return PromptResult.succeededReload;
            }
          });

          await sut.run(testMachineName);
          verifyInOrder([
            () =>
                mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
            () => mockPackageFileAdapter.loadPackageFileHierarchy(
              testMachineName,
            ),
            () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
            () => mockPrompter.writeTitle(
              messagePrefix: any(named: 'messagePrefix'),
              messageHighlight: diffEntries[0].package,
              messageSuffix: any(named: 'messageSuffix'),
              color: any(named: 'color'),
            ),
            () => mockPrompter.promptCommand(
              packageName: diffEntries[0].package,
              commands: any(named: 'commands'),
            ),
            () => mockPrompter.writeTitle(
              messagePrefix: any(named: 'messagePrefix'),
              messageHighlight: diffEntries[1].package,
              messageSuffix: any(named: 'messageSuffix'),
              color: any(named: 'color'),
            ),
            () => mockPrompter.promptCommand(
              packageName: diffEntries[1].package,
              commands: any(named: 'commands'),
            ),
            () => mockPackageSync.updatePackageDiff(),
            () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
            () => mockPrompter.writeTitle(
              messagePrefix: any(named: 'messagePrefix'),
              messageHighlight: diffEntries[0].package,
              messageSuffix: any(named: 'messageSuffix'),
              color: any(named: 'color'),
            ),
            () => mockPrompter.promptCommand(
              packageName: diffEntries[0].package,
              commands: any(named: 'commands'),
            ),
            () => mockPrompter.writeTitle(
              messagePrefix: any(named: 'messagePrefix'),
              messageHighlight: diffEntries[1].package,
              messageSuffix: any(named: 'messageSuffix'),
              color: any(named: 'color'),
            ),
            () => mockPrompter.promptCommand(
              packageName: diffEntries[1].package,
              commands: any(named: 'commands'),
            ),
            () => mockPrompter.writeTitle(
              messagePrefix: any(named: 'messagePrefix'),
              messageHighlight: diffEntries[2].package,
              messageSuffix: any(named: 'messageSuffix'),
              color: any(named: 'color'),
            ),
            () => mockPrompter.promptCommand(
              packageName: diffEntries[2].package,
              commands: any(named: 'commands'),
            ),
            () => mockPackageSync.updatePackageDiff(),
          ]);
          verifyNoMoreInteractions(mockPrompter);
        },
      );

      test('does not repeat already skipped diff entries', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];
        const diffEntries = [
          DiffEntry.removed('package-1'),
          DiffEntry.added('package-2'),
          DiffEntry.added('package-3'),
        ];

        when(
          () => mockPackageFileAdapter.loadPackageFileHierarchy(any()),
        ).thenStream(Stream.fromIterable(testHierarchy));
        when(
          () => mockDiffFileAdapter.loadPackageDiff(any()),
        ).thenStream(Stream.fromIterable(diffEntries));
        when(
          () => mockPacman.checkIfPackageIsInstalled(any()),
        ).thenReturnAsync(false);
        when(
          () => mockPrompter.promptCommand(
            packageName: any(named: 'packageName'),
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.skipped);
        var didReload = false;
        when(
          () => mockPrompter.promptCommand(
            packageName: 'package-2',
            commands: any(named: 'commands'),
          ),
        ).thenAnswer((_) {
          if (didReload) {
            return PromptResult.succeeded;
          } else {
            didReload = true;
            return PromptResult.succeededReload;
          }
        });

        await sut.run(testMachineName);
        verifyInOrder([
          () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
          () => mockPrompter.writeTitle(
            messagePrefix: any(named: 'messagePrefix'),
            messageHighlight: diffEntries[0].package,
            messageSuffix: any(named: 'messageSuffix'),
            color: any(named: 'color'),
          ),
          () => mockPrompter.promptCommand(
            packageName: diffEntries[0].package,
            commands: any(named: 'commands'),
          ),
          () => mockPrompter.writeTitle(
            messagePrefix: any(named: 'messagePrefix'),
            messageHighlight: diffEntries[1].package,
            messageSuffix: any(named: 'messageSuffix'),
            color: any(named: 'color'),
          ),
          () => mockPrompter.promptCommand(
            packageName: diffEntries[1].package,
            commands: any(named: 'commands'),
          ),
          () => mockPackageSync.updatePackageDiff(),
          () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
          () => mockPrompter.writeTitle(
            messagePrefix: any(named: 'messagePrefix'),
            messageHighlight: diffEntries[1].package,
            messageSuffix: any(named: 'messageSuffix'),
            color: any(named: 'color'),
          ),
          () => mockPrompter.promptCommand(
            packageName: diffEntries[1].package,
            commands: any(named: 'commands'),
          ),
          () => mockPrompter.writeTitle(
            messagePrefix: any(named: 'messagePrefix'),
            messageHighlight: diffEntries[2].package,
            messageSuffix: any(named: 'messageSuffix'),
            color: any(named: 'color'),
          ),
          () => mockPrompter.promptCommand(
            packageName: diffEntries[2].package,
            commands: any(named: 'commands'),
          ),
          () => mockPackageSync.updatePackageDiff(),
        ]);
        verifyNoMoreInteractions(mockPrompter);
      });
    });
  });
}
