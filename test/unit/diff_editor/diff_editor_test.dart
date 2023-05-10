// ignore_for_file: unnecessary_lambdas

import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mocktail/mocktail.dart';
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

class MockPrompter extends Mock implements Prompter {}

class MockStdout extends Mock implements Stdout {}

final mockStdout = MockStdout();

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
    final mockPrompter = MockPrompter();

    late DiffEditor sut;

    setUp(() async {
      reset(mockPackageFileAdapter);
      reset(mockDiffFileAdapter);
      reset(mockPacman);
      reset(mockPackageSync);
      reset(mockStdout);
      reset(mockPrompter);

      when(
        () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
      ).thenReturnAsync(null);

      sut = DiffEditor(
        mockPackageFileAdapter,
        mockDiffFileAdapter,
        mockPacman,
        mockPackageSync,
        mockPrompter,
      );
    });

    @isTest
    void testZoned(String description, dynamic Function() body) => test(
          description,
          () => IOOverrides.runZoned<dynamic>(
            stdout: () => mockStdout,
            body,
          ),
        );

    group('run', () {
      setUp(() async {
        when(() => mockStdout.hasTerminal).thenReturn(true);
        when(() => mockStdout.supportsAnsiEscapes).thenReturn(true);
        when(() => mockStdout.terminalColumns).thenReturn(80);

        when(() => mockPackageSync.updatePackageDiff()).thenReturnAsync(0);
      });

      testZoned('throws exception if console does not have a terminal',
          () async {
        when(() => mockStdout.hasTerminal).thenReturn(false);

        expect(() => sut.run(testMachineName), throwsA(isException));

        verify(() => mockStdout.hasTerminal);
      });

      testZoned('does nothing if no entries are present', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];

        when(() => mockPackageFileAdapter.loadPackageFileHierarchy(any()))
            .thenStream(Stream.fromIterable(testHierarchy));
        when(() => mockDiffFileAdapter.loadPackageDiff(any()))
            .thenStream(const Stream.empty());

        await sut.run(testMachineName);

        verifyInOrder([
          () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
        ]);
        verifyNoMoreInteractions(mockPackageSync);
      });

      testZoned('presents added diff entry', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];
        const diffEntry = DiffEntry.added('package-1');

        when(() => mockPackageFileAdapter.loadPackageFileHierarchy(any()))
            .thenStream(Stream.fromIterable(testHierarchy));
        when(() => mockDiffFileAdapter.loadPackageDiff(any()))
            .thenStream(Stream.value(diffEntry));
        when(
          () => mockPrompter.prompt(
            console: any(named: 'console'),
            packageName: any(named: 'packageName'),
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.succeeded);

        await sut.run(testMachineName);

        final captured = verifyInOrder([
          () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
          () => mockPrompter.writeTitle(
                console: any(named: 'console'),
                messagePrefix: 'Found installed package ',
                package: diffEntry.package,
                messageSuffix: ' that is not in the history yet!',
                color: ConsoleColor.green,
              ),
          () => mockPrompter.prompt(
                console: any(named: 'console'),
                packageName: diffEntry.package,
                commands: captureAny(named: 'commands'),
              ),
          () => mockPackageSync.updatePackageDiff(),
        ]).captured[4].single as List<PromptCommand>;

        expect(captured, hasLength(8));
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
        expect(
          captured,
          contains(isA<RemoveCommand>()),
        );
        expect(
          captured,
          contains(isA<MarkImplicitlyInstalledCommand>()),
        );
        expect(
          captured,
          contains(
            isA<AddHistoryCommand>()
                .having(
                  (c) => c.index,
                  'index',
                  0,
                )
                .having(
                  (c) => c.machineName,
                  'index',
                  testHierarchy[0],
                ),
          ),
        );
        expect(
          captured,
          contains(
            isA<AddHistoryCommand>()
                .having(
                  (c) => c.index,
                  'index',
                  1,
                )
                .having(
                  (c) => c.machineName,
                  'index',
                  testHierarchy[1],
                ),
          ),
        );
        expect(
          captured,
          contains(
            isA<AddHistoryCommand>()
                .having(
                  (c) => c.index,
                  'index',
                  2,
                )
                .having(
                  (c) => c.machineName,
                  'index',
                  testHierarchy[2],
                ),
          ),
        );
        expect(
          captured,
          contains(isA<SkipCommand>()),
        );
        expect(
          captured,
          contains(isA<QuitCommand>()),
        );
      });

      testZoned('presents removed diff entry for removed package', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];
        const diffEntry = DiffEntry.removed('package-1');

        when(() => mockPackageFileAdapter.loadPackageFileHierarchy(any()))
            .thenStream(Stream.fromIterable(testHierarchy));
        when(() => mockDiffFileAdapter.loadPackageDiff(any()))
            .thenStream(Stream.value(diffEntry));
        when(() => mockPacman.checkIfPackageIsInstalled(any()))
            .thenReturnAsync(false);
        when(
          () => mockPrompter.prompt(
            console: any(named: 'console'),
            packageName: any(named: 'packageName'),
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.succeeded);

        await sut.run(testMachineName);

        final captured = verifyInOrder([
          () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
          () => mockPacman.checkIfPackageIsInstalled(diffEntry.package),
          () => mockPrompter.writeTitle(
                console: any(named: 'console'),
                messagePrefix: 'Found uninstalled package ',
                package: diffEntry.package,
                messageSuffix: ' that is in the history!',
                color: ConsoleColor.red,
              ),
          () => mockPrompter.prompt(
                console: any(named: 'console'),
                packageName: diffEntry.package,
                commands: captureAny(named: 'commands'),
              ),
          () => mockPackageSync.updatePackageDiff(),
        ]).captured[5].single as List<PromptCommand>;

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
        expect(
          captured,
          contains(isA<InstallCommand>()),
        );
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
        expect(
          captured,
          contains(isA<SkipCommand>()),
        );
        expect(
          captured,
          contains(isA<QuitCommand>()),
        );
      });

      testZoned('presents removed diff entry for implicitly installed package',
          () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];
        const diffEntry = DiffEntry.removed('package-1');

        when(() => mockPackageFileAdapter.loadPackageFileHierarchy(any()))
            .thenStream(Stream.fromIterable(testHierarchy));
        when(() => mockDiffFileAdapter.loadPackageDiff(any()))
            .thenStream(Stream.value(diffEntry));
        when(() => mockPacman.checkIfPackageIsInstalled(any()))
            .thenReturnAsync(true);
        when(
          () => mockPrompter.prompt(
            console: any(named: 'console'),
            packageName: any(named: 'packageName'),
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.succeeded);

        await sut.run(testMachineName);

        final captured = verifyInOrder([
          () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockDiffFileAdapter.loadPackageDiff(testMachineName),
          () => mockPacman.checkIfPackageIsInstalled(diffEntry.package),
          () => mockPrompter.writeTitle(
                console: any(named: 'console'),
                messagePrefix: 'Found implicitly installed package ',
                package: diffEntry.package,
                messageSuffix: ' that is in the history!',
                color: ConsoleColor.yellow,
              ),
          () => mockPrompter.prompt(
                console: any(named: 'console'),
                packageName: diffEntry.package,
                commands: captureAny(named: 'commands'),
              ),
          () => mockPackageSync.updatePackageDiff(),
        ]).captured[5].single as List<PromptCommand>;

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
        expect(
          captured,
          contains(isA<MarkExplicitlyInstalledCommand>()),
        );
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
        expect(
          captured,
          contains(isA<SkipCommand>()),
        );
        expect(
          captured,
          contains(isA<QuitCommand>()),
        );
      });

      testZoned('aborts early if a command returns false', () async {
        const testHierarchy = [testMachineName, 'file2', 'file3'];
        const diffEntries = [
          DiffEntry.removed('package-1'),
          DiffEntry.added('package-2'),
          DiffEntry.added('package-3'),
        ];

        when(() => mockPackageFileAdapter.loadPackageFileHierarchy(any()))
            .thenStream(Stream.fromIterable(testHierarchy));
        when(() => mockDiffFileAdapter.loadPackageDiff(any()))
            .thenStream(Stream.fromIterable(diffEntries));
        when(() => mockPacman.checkIfPackageIsInstalled(any()))
            .thenReturnAsync(false);
        when(
          () => mockPrompter.prompt(
            console: any(named: 'console'),
            packageName: any(named: 'packageName'),
            commands: any(named: 'commands'),
          ),
        ).thenReturn(PromptResult.succeeded);
        when(
          () => mockPrompter.prompt(
            console: any(named: 'console'),
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
                console: any(named: 'console'),
                messagePrefix: any(named: 'messagePrefix'),
                package: diffEntries[0].package,
                messageSuffix: any(named: 'messageSuffix'),
                color: any(named: 'color'),
              ),
          () => mockPrompter.prompt(
                console: any(named: 'console'),
                packageName: diffEntries[0].package,
                commands: any(named: 'commands'),
              ),
          () => mockPrompter.writeTitle(
                console: any(named: 'console'),
                messagePrefix: any(named: 'messagePrefix'),
                package: diffEntries[1].package,
                messageSuffix: any(named: 'messageSuffix'),
                color: any(named: 'color'),
              ),
          () => mockPrompter.prompt(
                console: any(named: 'console'),
                packageName: diffEntries[1].package,
                commands: any(named: 'commands'),
              ),
          () => mockPackageSync.updatePackageDiff(),
        ]);
        verifyNoMoreInteractions(mockPrompter);
      });
    });
  });
}
