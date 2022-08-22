import 'package:args/args.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/command/install_command.dart';
import 'package:paxchange/src/config.dart';
import 'package:paxchange/src/package_install.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class MockArgResults extends Mock implements ArgResults {}

class MockConfig extends Mock implements Config {}

class MockPackageInstall extends Mock implements PackageInstall {}

class TestableInstallCommand extends InstallCommand {
  @override
  ArgResults? argResults;

  TestableInstallCommand(super.providerContainer);
}

void main() {
  group('$InstallCommand', () {
    final mockArgResults = MockArgResults();
    final mockConfig = MockConfig();
    final mockPackageInstall = MockPackageInstall();

    late ProviderContainer providerContainer;

    late TestableInstallCommand sut;

    setUp(() {
      reset(mockArgResults);
      reset(mockConfig);
      reset(mockPackageInstall);

      when(() => mockPackageInstall.installPackages(any())).thenReturnAsync(10);

      providerContainer = ProviderContainer(
        overrides: [
          configProvider.overrideWithValue(mockConfig),
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
      expect(sut.argParser.options, hasLength(2));
      expect(
        sut.argParser.options,
        contains(InstallCommand.machineNameOption),
      );
    });

    group('run', () {
      test('runs install with default machine name', () async {
        const rootPackageFile = 'root-package';
        when<dynamic>(() => mockArgResults[any()]).thenReturn(null);
        when(() => mockConfig.rootPackageFile).thenReturn(rootPackageFile);

        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[InstallCommand.machineNameOption],
          () => mockConfig.rootPackageFile,
          () => mockPackageInstall.installPackages(rootPackageFile),
        ]);
        expect(result, 10);
      });

      test('runs install with custom machine name', () async {
        const rootPackageFile = 'root-package';
        const givenPackageFile = 'other-package';
        when<dynamic>(() => mockArgResults[any()]).thenReturn(givenPackageFile);
        when(() => mockConfig.rootPackageFile).thenReturn(rootPackageFile);

        final result = await sut.run();

        verifyInOrder<dynamic>([
          () => mockArgResults[InstallCommand.machineNameOption],
          () => mockPackageInstall.installPackages(givenPackageFile),
        ]);
        expect(result, 10);
      });
    });
  });
}
