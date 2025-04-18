// ignore_for_file: discarded_futures

import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/command/review_command.dart';
import 'package:paxchange/src/config.dart';
import 'package:paxchange/src/diff_editor/editor.dart';
import 'package:paxchange/src/diff_editor/editors/cleanup_editor.dart';
import 'package:paxchange/src/diff_editor/editors/diff_editor.dart';
import 'package:paxchange/src/diff_editor/editors/missing_groups_editor.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class MockArgResults extends Mock implements ArgResults {}

class MockEditor extends Mock implements Editor {}

class MockMissingGroupsEditor extends Mock implements MissingGroupsEditor {}

class MockDiffEditor extends Mock implements DiffEditor {}

class MockCleanupEditor extends Mock implements CleanupEditor {}

class TestableReviewCommand extends ReviewCommand {
  @override
  ArgResults? argResults;

  TestableReviewCommand(super._providerContainer);
}

void main() {
  group('$ReviewCommand', () {
    const testMachineNameOption = 'machine-name';
    const testIncludeOptionalOption = 'include-optional';

    const rootPackageFile = 'root-package';
    final testConfig = Config(
      storageDirectory: Directory.systemTemp,
      machineName: rootPackageFile,
    );
    final mockArgResults = MockArgResults();
    final mockEditor = MockEditor();
    final mockMissingGroupsEditor = MockMissingGroupsEditor();
    final mockDiffEditor = MockDiffEditor();
    final mockCleanupEditor = MockCleanupEditor();

    late ProviderContainer providerContainer;

    late TestableReviewCommand sut;

    setUp(() {
      reset(mockArgResults);
      reset(mockEditor);
      reset(mockMissingGroupsEditor);
      reset(mockDiffEditor);
      reset(mockCleanupEditor);

      when(() => mockEditor.run(any())).thenReturnAsync(null);

      providerContainer = ProviderContainer(
        overrides: [
          missingGroupsEditorProvider.overrideWithValue(
            mockMissingGroupsEditor,
          ),
          diffEditorProvider.overrideWithValue(mockDiffEditor),
          cleanupEditorProvider(
            includeOptional: false,
          ).overrideWithValue(mockCleanupEditor),
          cleanupEditorProvider(
            includeOptional: true,
          ).overrideWithValue(mockCleanupEditor),
          configProvider.overrideWithValue(testConfig),
          editorProvider(
            Editors([
              mockMissingGroupsEditor,
              mockDiffEditor,
              mockCleanupEditor,
            ]),
          ).overrideWithValue(mockEditor),
        ],
      );

      sut = TestableReviewCommand(providerContainer)
        ..argResults = mockArgResults;
    });

    tearDown(() {
      providerContainer.dispose();
    });

    test('is correctly configured', () {
      expect(sut.name, 'review');
      expect(sut.description, isNotEmpty);
      expect(sut.takesArguments, isFalse);
      expect(sut.argParser.options, hasLength(3));
      expect(sut.argParser.options, contains(testMachineNameOption));
      expect(sut.argParser.options, contains(testIncludeOptionalOption));
    });

    group('run', () {
      test('runs diff editor with default machine name', () async {
        when<dynamic>(
          () => mockArgResults[testMachineNameOption],
        ).thenReturn(null);
        when<dynamic>(
          () => mockArgResults[testIncludeOptionalOption],
        ).thenReturn(false);

        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[testMachineNameOption],
          () => mockArgResults[testIncludeOptionalOption],
          () => mockEditor.run(rootPackageFile),
        ]);
        expect(result, 0);
      });

      test('runs diff editor with custom machine name', () async {
        const givenPackageFile = 'other-package';

        when<dynamic>(
          () => mockArgResults[testMachineNameOption],
        ).thenReturn(givenPackageFile);
        when<dynamic>(
          () => mockArgResults[testIncludeOptionalOption],
        ).thenReturn(false);
        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[testMachineNameOption],
          () => mockArgResults[testIncludeOptionalOption],
          () => mockEditor.run(givenPackageFile),
        ]);
        expect(result, 0);
      });
    });
  });
}
