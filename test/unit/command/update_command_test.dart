// ignore_for_file: unnecessary_lambdas for tests

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

class TestableUpdateCommand extends UpdateCommand {
  @override
  ArgResults? argResults;

  TestableUpdateCommand(super._providerContainer);
}

void main() {
  group('$UpdateCommand', () {
    const testSetExitOnChangedFlag = 'set-exit-on-changed';

    final mockPackageSync = MockPackageSync();
    final mockArgResults = MockArgResults();
    final mockStdout = MockStdout();

    late ProviderContainer providerContainer;

    late TestableUpdateCommand sut;

    setUp(() {
      reset(mockPackageSync);
      reset(mockArgResults);
      reset(mockStdout);

      providerContainer = ProviderContainer(
        overrides: [packageSyncProvider.overrideWithValue(mockPackageSync)],
      );

      sut = TestableUpdateCommand(providerContainer)
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
      expect(sut.argParser.options, contains(testSetExitOnChangedFlag));
    });

    group('run', () {
      test(
        'calls packageSync.updatePackageDiff',
        () async => await IOOverrides.runZoned(
          stdout: () => mockStdout,
          () async {
            when(() => mockPackageSync.updatePackageDiff()).thenReturnAsync(0);

            final result = await sut.run();

            verify(() => mockPackageSync.updatePackageDiff());
            verifyZeroInteractions(mockStdout);
            expect(result, 0);
          },
        ),
      );

      test(
        'returns 0 even if packages did change and write to stdout',
        () async => await IOOverrides.runZoned(
          stdout: () => mockStdout,
          () async {
            when<dynamic>(() => mockArgResults[any()]).thenReturn(false);
            when(() => mockPackageSync.updatePackageDiff()).thenReturnAsync(10);

            final result = await sut.run();

            verifyInOrder<dynamic>([
              () => mockPackageSync.updatePackageDiff(),
              () => mockStdout.writeln('>>> 10 package(s) have changed!'),
              () => mockStdout.writeln(
                '>>> Please review the package changelog.',
              ),
              () => mockArgResults[testSetExitOnChangedFlag],
            ]);
            expect(result, 0);
          },
        ),
      );

      test(
        'returns 2 if packages did change with option specified',
        () async => await IOOverrides.runZoned(
          stdout: () => mockStdout,
          () async {
            when<dynamic>(() => mockArgResults[any()]).thenReturn(true);
            when(() => mockPackageSync.updatePackageDiff()).thenReturnAsync(10);

            final result = await sut.run();

            verifyInOrder<dynamic>([
              () => mockPackageSync.updatePackageDiff(),
              () => mockStdout.writeln('>>> 10 package(s) have changed!'),
              () => mockStdout.writeln(
                '>>> Please review the package changelog.',
              ),
              () => mockArgResults[testSetExitOnChangedFlag],
            ]);
            expect(result, 2);
          },
        ),
      );
    });
  });
}
