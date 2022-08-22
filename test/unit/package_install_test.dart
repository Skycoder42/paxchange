import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/package_install.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:test/test.dart';

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockPacman extends Mock implements Pacman {}

void main() {
  group('$PackageInstall', () {
    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockPacman = MockPacman();

    late PackageInstall sut;

    setUp(() {
      reset(mockPackageFileAdapter);
      reset(mockPacman);

      sut = PackageInstall(
        mockPackageFileAdapter,
        mockPacman,
      );
    });

    testData<bool>(
      'installPackages streams packages for machine name and installs them',
      const [false, true],
      (noConfirm) async {
        const testMachineName = 'test-machine';
        const packages = ['p1', 'p2', 'p3'];

        when(() => mockPackageFileAdapter.loadPackageFile(any()))
            .thenStream(Stream.fromIterable(packages));
        when(
          () => mockPacman.installPackages(
            any(),
            onlyNeeded: any(named: 'onlyNeeded'),
            noConfirm: any(named: 'noConfirm'),
          ),
        ).thenReturnAsync(42);

        final result = await sut.installPackages(
          testMachineName,
          noConfirm: noConfirm,
        );

        verifyInOrder([
          () => mockPackageFileAdapter.loadPackageFile(testMachineName),
          () => mockPacman.installPackages(
                packages,
                onlyNeeded: true,
                noConfirm: noConfirm,
              ),
        ]);
        expect(result, 42);
      },
    );
  });
}
