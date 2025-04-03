// ignore_for_file: discarded_futures

import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/command/install_command.dart';
import 'package:paxchange/src/config.dart';
import 'package:paxchange/src/package_install.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class MockArgResults extends Mock implements ArgResults {}

class MockPackageInstall extends Mock implements PackageInstall {}

class TestableInstallCommand extends InstallCommand {
  @override
  ArgResults? argResults;

  TestableInstallCommand(super._providerContainer);
}

void main() {
  group('$InstallCommand', () {
    const testMachineNameOption = 'machine-name';
    const testConfirmFlag = 'confirm';

    const rootPackageFile = 'root-package';
    final testConfig = Config(
      storageDirectory: Directory.systemTemp,
      machineName: rootPackageFile,
    );
    final mockArgResults = MockArgResults();
    final mockPackageInstall = MockPackageInstall();

    late ProviderContainer providerContainer;

    late TestableInstallCommand sut;

    setUp(() {
      reset(mockArgResults);
      reset(mockPackageInstall);

      when(
        () => mockPackageInstall.installPackages(
          any(),
          noConfirm: any(named: 'noConfirm'),
        ),
      ).thenReturnAsync(10);

      providerContainer = ProviderContainer(
        overrides: [
          configProvider.overrideWithValue(testConfig),
          packageInstallProvider.overrideWithValue(mockPackageInstall),
        ],
      );

      sut = TestableInstallCommand(providerContainer)
        ..argResults = mockArgResults;
    });

    tearDown(() {
      providerContainer.dispose();
    });

    test('is correctly configured', () {
      expect(sut.name, 'install');
      expect(sut.description, isNotEmpty);
      expect(sut.takesArguments, isFalse);
      expect(sut.argParser.options, hasLength(3));
      expect(sut.argParser.options, contains(testMachineNameOption));
      expect(sut.argParser.options, contains(testConfirmFlag));
    });

    group('run', () {
      test('runs install with default machine name', () async {
        when<dynamic>(
          () => mockArgResults[testMachineNameOption],
        ).thenReturn(null);
        when<dynamic>(() => mockArgResults[testConfirmFlag]).thenReturn(true);

        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[testMachineNameOption],
          () => mockPackageInstall.installPackages(rootPackageFile),
        ]);
        expect(result, 10);
      });

      test('runs install with custom machine name and no-confirm', () async {
        const givenPackageFile = 'other-package';
        when<dynamic>(
          () => mockArgResults[testMachineNameOption],
        ).thenReturn(givenPackageFile);
        when<dynamic>(() => mockArgResults[testConfirmFlag]).thenReturn(false);

        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[testMachineNameOption],
          () => mockPackageInstall.installPackages(
            givenPackageFile,
            noConfirm: true,
          ),
        ]);
        expect(result, 10);
      });
    });
  });
}
