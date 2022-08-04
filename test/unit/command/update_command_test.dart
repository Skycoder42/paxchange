import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/command/update_command.dart';
import 'package:paxchange/src/package_sync.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class MockArgResults extends Mock implements ArgResults {}

class MockPackageSync extends Mock implements PackageSync {}

class MockStdout extends Mock implements Stdout {}

class TestableUpdatePackageDiffCommand extends UpdateCommand {
  @override
  ArgResults? argResults;

  TestableUpdatePackageDiffCommand(super.providerContainer);
}

void main() {
  group('$UpdateCommand', () {
    final mockPackageSync = MockPackageSync();
    final mockArgResults = MockArgResults();
    final mockStdout = MockStdout();

    late ProviderContainer providerContainer;

    late TestableUpdatePackageDiffCommand sut;

    setUp(() {
      reset(mockPackageSync);
      reset(mockArgResults);
      reset(mockStdout);

      providerContainer = ProviderContainer(
        overrides: [
          packageSyncProvider.overrideWithValue(mockPackageSync),
        ],
      );

      sut = TestableUpdatePackageDiffCommand(providerContainer)
        ..argResults = mockArgResults;
    });

    tearDown(() {
      providerContainer.dispose();
    });

    test('is correctly configured', () {
      expect(sut.name, 'update');
      expect(sut.description, isNotEmpty);
      expect(sut.takesArguments, isFalse);
      expect(sut.argParser.options, hasLength(2));
      expect(
        sut.argParser.options,
        contains(UpdateCommand.setExitOnChangedFlag),
      );
    });

    group('run', () {
      test(
        'calls packageSync.updatePackageDiff',
        () => IOOverrides.runZoned(
          stdout: () => mockStdout,
          () async {
            when<dynamic>(() => mockArgResults[any()]).thenReturn(false);
            when(() => mockPackageSync.updatePackageDiff()).thenReturnAsync(0);

            final result = await sut.run();

            verifyInOrder<dynamic>([
              () => mockArgResults[UpdateCommand.setExitOnChangedFlag],
              () => mockPackageSync.updatePackageDiff(),
            ]);
            verifyZeroInteractions(mockStdout);
            expect(result, 0);
          },
        ),
      );

      test(
        'returns 0 even if packages did change and write to stdout',
        () => IOOverrides.runZoned(
          stdout: () => mockStdout,
          () async {
            when<dynamic>(() => mockArgResults[any()]).thenReturn(false);
            when(() => mockPackageSync.updatePackageDiff()).thenReturnAsync(10);

            final result = await sut.run();

            verifyInOrder<dynamic>([
              () => mockArgResults[UpdateCommand.setExitOnChangedFlag],
              () => mockPackageSync.updatePackageDiff(),
              () => mockStdout.writeln('>>> 10 package(s) have changed!'),
              () => mockStdout.writeln(
                    '>>> Please review the package changelog.',
                  ),
            ]);
            expect(result, 0);
          },
        ),
      );

      test(
        'returns 2 if packages did change with option specified',
        () => IOOverrides.runZoned(
          stdout: () => mockStdout,
          () async {
            when<dynamic>(() => mockArgResults[any()]).thenReturn(true);
            when(() => mockPackageSync.updatePackageDiff()).thenReturnAsync(10);

            final result = await sut.run();

            verifyInOrder<dynamic>([
              () => mockArgResults[UpdateCommand.setExitOnChangedFlag],
              () => mockPackageSync.updatePackageDiff(),
              () => mockStdout.writeln('>>> 10 package(s) have changed!'),
              () => mockStdout.writeln(
                    '>>> Please review the package changelog.',
                  ),
            ]);
            expect(result, 2);
          },
        ),
      );
    });
  });
}
