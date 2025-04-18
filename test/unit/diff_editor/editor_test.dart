// ignore_for_file: unnecessary_lambdas, discarded_futures

import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/commands/quit_command.dart';
import 'package:paxchange/src/diff_editor/commands/skip_command.dart';
import 'package:paxchange/src/diff_editor/editor.dart';
import 'package:paxchange/src/diff_editor/editors/command_editor.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/package_sync.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:paxchange/src/storage/package_file_hierarchy.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

class MockPrompter extends Mock implements Prompter {}

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockPackageSync extends Mock implements PackageSync {}

class MockCommandEditor<T> extends Mock implements CommandEditor<T> {}

final class FakePromptCommand extends PromptCommand with Fake {
  FakePromptCommand() : super(MockConsole(), '');
}

void main() {
  setUpAll(() {
    registerFallbackValue(PackageFileHierarchy.empty);
  });

  group('$Editor', () {
    const testMachineName = 'test-machine';
    const testHierarchy = PackageFileHierarchy(
      packageFiles: {testMachineName, 'machine-2', 'machine-3'},
      groupsByPackages: {},
    );
    final testCommand1 = FakePromptCommand();
    final testCommand2 = FakePromptCommand();

    final mockConsole = MockConsole();
    final mockPrompter = MockPrompter();
    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockPackageSync = MockPackageSync();
    final mockCommandEditor1 = MockCommandEditor<String>();
    final mockCommandEditor2 = MockCommandEditor<int>();

    late Editor sut;

    setUp(() {
      reset(mockConsole);
      reset(mockPrompter);
      reset(mockPackageFileAdapter);
      reset(mockPackageSync);
      reset(mockCommandEditor1);
      reset(mockCommandEditor2);

      when(() => mockConsole.hasTerminal).thenReturn(true);
      when(() => mockConsole.readKey()).thenReturn(Key.printable(' '));

      when(
        () => mockPackageFileAdapter.ensurePackageFileExists(any()),
      ).thenReturnAsync(null);
      when(
        () => mockPackageFileAdapter.loadPackageFileHierarchy(any()),
      ).thenReturnAsync(testHierarchy);

      when(() => mockPackageSync.updatePackageDiff()).thenReturnAsync(0);

      when(
        () => mockCommandEditor1.loadTargets(any(), any()),
      ).thenStream(const Stream.empty());
      when(
        () => mockCommandEditor1.buildCommands(any(), any(), any()),
      ).thenAnswer((_) => Stream.value(testCommand1));
      when(
        () => mockCommandEditor2.loadTargets(any(), any()),
      ).thenStream(const Stream.empty());
      when(
        () => mockCommandEditor2.buildCommands(any(), any(), any()),
      ).thenAnswer((_) => Stream.value(testCommand2));

      when(
        () => mockPrompter.promptCommand(any()),
      ).thenReturn(PromptResult.succeeded);

      sut = Editor(
        mockConsole,
        mockPrompter,
        mockPackageFileAdapter,
        mockPackageSync,
        [mockCommandEditor1, mockCommandEditor2],
      );
    });

    group('run', () {
      void ensureNoMoreInteractions() => addTearDown(() {
        verifyNoMoreInteractions(mockPrompter);
        verifyNoMoreInteractions(mockPackageFileAdapter);
        verifyNoMoreInteractions(mockPackageSync);
        verifyNoMoreInteractions(mockCommandEditor1);
        verifyNoMoreInteractions(mockCommandEditor2);
      });

      test('throws exception if console does not have a terminal', () {
        ensureNoMoreInteractions();

        when(() => mockConsole.hasTerminal).thenReturn(false);

        expect(() => sut.run(testMachineName), throwsA(isException));

        verify(() => mockConsole.hasTerminal);
      });

      test(
        'setups package file and loads hierarchy before running editors',
        () async {
          await sut.run(testMachineName);

          verifyInOrder([
            () =>
                mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
            () => mockPackageFileAdapter.loadPackageFileHierarchy(
              testMachineName,
            ),
          ]);
        },
      );

      test('does nothing if no editor returns any targets', () async {
        ensureNoMoreInteractions();

        await sut.run(testMachineName);

        verifyInOrder([
          () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockCommandEditor1.loadTargets(testMachineName, testHierarchy),
          () => mockCommandEditor2.loadTargets(testMachineName, testHierarchy),
        ]);
      });

      test(
        'runs each editors for their targets and updates diff in the end',
        () async {
          ensureNoMoreInteractions();

          const targets1 = ['target-1-1', 'target-1-2'];
          const targets2 = [21, 22];
          when(
            () => mockCommandEditor1.loadTargets(any(), any()),
          ).thenStream(Stream.fromIterable(targets1));
          when(
            () => mockCommandEditor2.loadTargets(any(), any()),
          ).thenStream(Stream.fromIterable(targets2));

          await sut.run(testMachineName);

          verifyInOrder([
            () =>
                mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
            () => mockPackageFileAdapter.loadPackageFileHierarchy(
              testMachineName,
            ),
            () =>
                mockCommandEditor1.loadTargets(testMachineName, testHierarchy),
            for (final target in targets1) ...[
              () => mockCommandEditor1.buildCommands(
                testMachineName,
                testHierarchy,
                target,
              ),
              () => mockPrompter.promptCommand(
                any(
                  that: containsAllInOrder([
                    testCommand1,
                    isA<SkipCommand>(),
                    isA<QuitCommand>(),
                  ]),
                ),
              ),
              () => mockConsole.readKey(),
            ],
            () =>
                mockCommandEditor2.loadTargets(testMachineName, testHierarchy),
            for (final target in targets2) ...[
              () => mockCommandEditor2.buildCommands(
                testMachineName,
                testHierarchy,
                target,
              ),
              () => mockPrompter.promptCommand(
                any(
                  that: containsAllInOrder([
                    testCommand2,
                    isA<SkipCommand>(),
                    isA<QuitCommand>(),
                  ]),
                ),
              ),
              () => mockConsole.readKey(),
            ],
            () => mockPackageSync.updatePackageDiff(),
          ]);
        },
      );

      test('skips other editors if first editor returns quit', () async {
        when(
          () => mockCommandEditor1.loadTargets(any(), any()),
        ).thenStream(Stream.value('test-target'));

        when(
          () => mockPrompter.promptCommand(any()),
        ).thenReturn(PromptResult.quit);

        await sut.run(testMachineName);

        verify(
          () => mockCommandEditor1.loadTargets(testMachineName, testHierarchy),
        );
        verifyNever(() => mockCommandEditor2.loadTargets(any(), any()));
        verifyNever(() => mockConsole.readKey());
        verifyNoMoreInteractions(mockPackageSync);
      });

      test(
        'skips other editors if first editor fails but still updates diff',
        () async {
          ensureNoMoreInteractions();

          const target1 = 'target-1';
          when(
            () => mockCommandEditor1.loadTargets(any(), any()),
          ).thenStream(Stream.value(target1));

          when(
            () => mockPrompter.promptCommand(any()),
          ).thenReturn(PromptResult.failed);

          await sut.run(testMachineName);

          verifyInOrder([
            () =>
                mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
            () => mockPackageFileAdapter.loadPackageFileHierarchy(
              testMachineName,
            ),
            () =>
                mockCommandEditor1.loadTargets(testMachineName, testHierarchy),
            () => mockCommandEditor1.buildCommands(
              testMachineName,
              testHierarchy,
              target1,
            ),
            () => mockPrompter.promptCommand(any()),
            () => mockConsole.readKey(),
            () => mockPackageSync.updatePackageDiff(),
          ]);
        },
      );

      test(
        'reloads hierarchy and starts a new if editor returns succeededReload',
        () async {
          ensureNoMoreInteractions();

          const target11 = 'target-1-1';
          const targets1 = [target11, 'target-1-2'];
          const target2 = 2;
          when(
            () => mockCommandEditor1.loadTargets(any(), any()),
          ).thenAnswer((_) => Stream.fromIterable(targets1));
          when(
            () => mockCommandEditor2.loadTargets(any(), any()),
          ).thenAnswer((_) => Stream.value(target2));

          var didReload = false;
          when(() => mockPrompter.promptCommand(any())).thenAnswer((_) {
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
            () =>
                mockCommandEditor1.loadTargets(testMachineName, testHierarchy),
            () => mockCommandEditor1.buildCommands(
              testMachineName,
              testHierarchy,
              target11,
            ),
            () => mockPrompter.promptCommand(any()),
            () => mockConsole.readKey(),
            () => mockPackageSync.updatePackageDiff(),
            () => mockPackageFileAdapter.loadPackageFileHierarchy(
              testMachineName,
            ),
            () =>
                mockCommandEditor1.loadTargets(testMachineName, testHierarchy),
            for (final target in targets1) ...[
              () => mockCommandEditor1.buildCommands(
                testMachineName,
                testHierarchy,
                target,
              ),
              () => mockPrompter.promptCommand(any()),
              () => mockConsole.readKey(),
            ],
            () =>
                mockCommandEditor2.loadTargets(testMachineName, testHierarchy),
            () => mockCommandEditor2.buildCommands(
              testMachineName,
              testHierarchy,
              target2,
            ),
            () => mockPrompter.promptCommand(any()),
            () => mockConsole.readKey(),
            () => mockPackageSync.updatePackageDiff(),
          ]);
        },
      );

      test('ignores already skipped targets and '
          'does not update diff if all are skipped', () async {
        ensureNoMoreInteractions();

        const target1 = 'target-1';
        const targets2 = [21, 22, 23];
        when(
          () => mockCommandEditor1.loadTargets(any(), any()),
        ).thenAnswer((_) => Stream.value(target1));
        when(
          () => mockCommandEditor2.loadTargets(any(), any()),
        ).thenAnswer((_) => Stream.fromIterable(targets2));

        var promptCnt = 0;
        when(() => mockPrompter.promptCommand(any())).thenAnswer((_) {
          if (promptCnt++ == 2) {
            return PromptResult.succeededReload;
          } else {
            return PromptResult.skipped;
          }
        });

        await sut.run(testMachineName);

        verifyInOrder([
          () => mockPackageFileAdapter.ensurePackageFileExists(testMachineName),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockCommandEditor1.loadTargets(testMachineName, testHierarchy),
          () => mockCommandEditor1.buildCommands(
            testMachineName,
            testHierarchy,
            target1,
          ),
          () => mockPrompter.promptCommand(any()),
          () => mockCommandEditor2.loadTargets(testMachineName, testHierarchy),
          for (final target in targets2.take(2)) ...[
            () => mockCommandEditor2.buildCommands(
              testMachineName,
              testHierarchy,
              target,
            ),
            () => mockPrompter.promptCommand(any()),
          ],
          () => mockConsole.readKey(),
          () => mockPackageSync.updatePackageDiff(),
          () =>
              mockPackageFileAdapter.loadPackageFileHierarchy(testMachineName),
          () => mockCommandEditor1.loadTargets(testMachineName, testHierarchy),
          () => mockCommandEditor2.loadTargets(testMachineName, testHierarchy),
          for (final target in targets2.skip(1)) ...[
            () => mockCommandEditor2.buildCommands(
              testMachineName,
              testHierarchy,
              target,
            ),
            () => mockPrompter.promptCommand(any()),
          ],
        ]);
      });
    });
  });
}
