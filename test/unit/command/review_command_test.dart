import 'package:args/args.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/command/review_command.dart';
import 'package:paxchange/src/config.dart';
import 'package:paxchange/src/diff_editor/diff_editor.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class MockArgResults extends Mock implements ArgResults {}

class MockConfig extends Mock implements Config {}

class MockDiffEditor extends Mock implements DiffEditor {}

class TestableReviewCommand extends ReviewCommand {
  @override
  ArgResults? argResults;

  TestableReviewCommand(super._providerContainer);
}

void main() {
  group('$ReviewCommand', () {
    final mockArgResults = MockArgResults();
    final mockConfig = MockConfig();
    final mockDiffEditor = MockDiffEditor();

    late ProviderContainer providerContainer;

    late TestableReviewCommand sut;

    setUp(() async {
      reset(mockArgResults);
      reset(mockConfig);
      reset(mockDiffEditor);

      when(() => mockDiffEditor.run(any())).thenReturnAsync(null);

      providerContainer = ProviderContainer(
        overrides: [
          configProvider.overrideWithValue(mockConfig),
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
      expect(
        sut.argParser.options,
        contains(ReviewCommand.machineNameOption),
      );
    });

    group('run', () {
      test('runs diff editor with default machine name', () async {
        const rootPackageFile = 'root-package';
        when<dynamic>(() => mockArgResults[any()]).thenReturn(null);
        when(() => mockConfig.rootPackageFile).thenReturn(rootPackageFile);

        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[ReviewCommand.machineNameOption],
          () => mockConfig.rootPackageFile,
          () => mockDiffEditor.run(rootPackageFile),
        ]);
        expect(result, 0);
      });

      test('runs diff editor with custom machine name', () async {
        const rootPackageFile = 'root-package';
        const givenPackageFile = 'other-package';
        when<dynamic>(() => mockArgResults[any()]).thenReturn(givenPackageFile);
        when(() => mockConfig.rootPackageFile).thenReturn(rootPackageFile);

        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[ReviewCommand.machineNameOption],
          () => mockDiffEditor.run(givenPackageFile),
        ]);
        expect(result, 0);
      });
    });
  });
}
