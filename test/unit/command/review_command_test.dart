// ignore_for_file: discarded_futures

import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/command/review_command.dart';
import 'package:paxchange/src/config.dart';
import 'package:paxchange/src/diff_editor/editors/diff_editor.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class MockArgResults extends Mock implements ArgResults {}

class MockDiffEditor extends Mock implements DiffEditor {}

class TestableReviewCommand extends ReviewCommand {
  @override
  ArgResults? argResults;

  TestableReviewCommand(super._providerContainer);
}

void main() {
  group('$ReviewCommand', () {
    const testMachineNameOption = 'machine-name';

    const rootPackageFile = 'root-package';
    final testConfig = Config(
      storageDirectory: Directory.systemTemp,
      machineName: rootPackageFile,
    );
    final mockArgResults = MockArgResults();
    final mockDiffEditor = MockDiffEditor();

    late ProviderContainer providerContainer;

    late TestableReviewCommand sut;

    setUp(() {
      reset(mockArgResults);
      reset(mockDiffEditor);

      when(() => mockDiffEditor.run(any())).thenReturnAsync(null);

      providerContainer = ProviderContainer(
        overrides: [
          configProvider.overrideWithValue(testConfig),
          diffEditorProvider.overrideWithValue(mockDiffEditor),
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
      expect(sut.argParser.options, hasLength(2));
      expect(sut.argParser.options, contains(testMachineNameOption));
    });

    group('run', () {
      test('runs diff editor with default machine name', () async {
        when<dynamic>(() => mockArgResults[any()]).thenReturn(null);

        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[testMachineNameOption],
          () => mockDiffEditor.run(rootPackageFile),
        ]);
        expect(result, 0);
      });

      test('runs diff editor with custom machine name', () async {
        const givenPackageFile = 'other-package';
        when<dynamic>(() => mockArgResults[any()]).thenReturn(givenPackageFile);

        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[testMachineNameOption],
          () => mockDiffEditor.run(givenPackageFile),
        ]);
        expect(result, 0);
      });
    });
  });
}
