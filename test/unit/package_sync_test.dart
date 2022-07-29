import 'dart:collection';

import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_entry.dart';
import 'package:paxchange/src/package_sync.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/storage/diff_file_adapter.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:test/test.dart';

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockDiffFileAdapter extends Mock implements DiffFileAdapter {}

class MockPacman extends Mock implements Pacman {}

void main() {
  group('$PackageSync', () {
    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockDiffFileAdapter = MockDiffFileAdapter();
    final mockPacman = MockPacman();

    late PackageSync sut;

    setUp(() {
      reset(mockPackageFileAdapter);
      reset(mockDiffFileAdapter);
      reset(mockPacman);

      sut = PackageSync(
        mockPackageFileAdapter,
        mockDiffFileAdapter,
        mockPacman,
      );
    });

    group('updatePackageDiff', () {
      test(
        'generates diff between installed and cached packages and saves it',
        () async {
          const testMachineName = 'test-machine';
          const packageHistory = [
            'package-2',
            'package-4',
            'package-6',
            'package-8',
          ];
          const installedPackages = [
            'package-4',
            'package-5',
            'package-7',
            'package-8',
          ];

          when(() => mockPackageFileAdapter.loadPackageFile(any()))
              .thenStream(Stream.fromIterable(packageHistory));
          when(mockPacman.listExplicitlyInstalledPackages)
              .thenStream(Stream.fromIterable(installedPackages));
          when(() => mockDiffFileAdapter.savePackageDiff(any(), any()))
              .thenReturnAsync(null);

          final result = await sut.updatePackageDiff(testMachineName);

          final captured = verifyInOrder([
            () => mockPackageFileAdapter.loadPackageFile(testMachineName),
            () => mockPacman.listExplicitlyInstalledPackages(),
            () => mockDiffFileAdapter.savePackageDiff(
                  testMachineName,
                  captureAny(),
                ),
          ]).captured[2].single as Set<DiffEntry>;

          expect(captured, isA<SplayTreeSet>());
          expect(
            captured,
            orderedEquals(const <DiffEntry>[
              DiffEntry.removed('package-2'),
              DiffEntry.added('package-5'),
              DiffEntry.removed('package-6'),
              DiffEntry.added('package-7'),
            ]),
          );

          expect(result, 4);
        },
      );

      test(
        'generates empty diff if packages are the same',
        () async {
          const testMachineName = 'test-machine';
          const packages = [
            'package-1',
            'package-2',
            'package-3',
            'package-4',
          ];

          when(() => mockPackageFileAdapter.loadPackageFile(any()))
              .thenStream(Stream.fromIterable(packages));
          when(mockPacman.listExplicitlyInstalledPackages)
              .thenStream(Stream.fromIterable(packages));
          when(() => mockDiffFileAdapter.savePackageDiff(any(), any()))
              .thenReturnAsync(null);

          final result = await sut.updatePackageDiff(testMachineName);

          verifyInOrder([
            () => mockPackageFileAdapter.loadPackageFile(testMachineName),
            () => mockPacman.listExplicitlyInstalledPackages(),
            () => mockDiffFileAdapter.savePackageDiff(
                  testMachineName,
                  any(that: isEmpty),
                ),
          ]);

          expect(result, 0);
        },
      );
    });
  });
}
