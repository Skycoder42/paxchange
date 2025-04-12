// ignore_for_file: discarded_futures

import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:paxchange/src/storage/package_file_hierarchy.dart';
import 'package:test/test.dart';

class MockPacman extends Mock implements Pacman {}

void main() {
  group('$LoadPackageFailure', () {
    test('toString creates correct string representation', () {
      final failure = LoadPackageFailure(
        fileName: 'test/file',
        history: const ['a', 'b', 'c'],
        message: 'It failed',
      );

      expect(
        failure.toString(),
        'test/file: It failed. Import history: a -> b -> c',
      );
    });
  });

  group('$PackageFileAdapter', () {
    final mockPacman = MockPacman();
    late Directory testDir;

    late PackageFileAdapter sut;

    setUp(() async {
      reset(mockPacman);

      testDir = await Directory.systemTemp.createTemp();

      sut = PackageFileAdapter(testDir, mockPacman);
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    File packageFile(String name) => File.fromUri(testDir.uri.resolve(name));

    void writeFile(String name, List<String> lines) =>
        packageFile(name).writeAsStringSync(lines.join('\n'));

    group('loadPackageFile', () {
      test('returns empty stream if file does not exist', () {
        final stream = sut.loadPackageFile('non-existent-file');
        expect(stream, emitsDone);
      });

      test('returns lines of a simple file', () {
        const fileName = 'test-file';
        const lines = ['line-A', 'line-B', 'line-C'];
        writeFile(fileName, lines);

        final stream = sut.loadPackageFile(fileName);
        expect(stream, emitsInOrder(<dynamic>[...lines, emitsDone]));
      });

      test('skips comment and empty lines', () {
        const fileName = 'test-file';
        const lines = [
          '   line-A     ',
          '',
          '# line-B',
          '  \t    ',
          '    # line-C',
        ];
        writeFile(fileName, lines);

        final stream = sut.loadPackageFile(fileName);
        expect(stream, emitsInOrder(<dynamic>[lines.first.trim(), emitsDone]));
      });

      test('imports other package files', () {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const lines1 = ['line-A', 'line-B', 'line-C'];
        const lines2 = ['::import $fileName1'];
        writeFile(fileName1, lines1);
        writeFile(fileName2, lines2);

        final stream = sut.loadPackageFile(fileName2);
        expect(stream, emitsInOrder(<dynamic>[...lines1, emitsDone]));
      });

      test('imports other package files recursively and keeps ordering', () {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const fileName3 = 'test-file-3';
        const fileName4 = 'test-file-4';
        const lines1 = ['line-A', 'line-B', 'line-C'];
        const lines2 = ['line-D', 'line-E', 'line-F'];
        const lines3 = [
          '   ::import $fileName2',
          'line-G',
          '::import $fileName1   ',
        ];
        const lines4 = ['#::import $fileName1', '::import $fileName3'];
        writeFile(fileName1, lines1);
        writeFile(fileName2, lines2);
        writeFile(fileName3, lines3);
        writeFile(fileName4, lines4);

        final stream = sut.loadPackageFile(fileName4);
        expect(
          stream,
          emitsInOrder(<dynamic>[...lines2, lines3[1], ...lines1, emitsDone]),
        );
      });

      test('throws exception if imported file cannot be found', () {
        const fileName1 = 'test-file';
        const lines1 = ['::import non-existent-file'];
        writeFile(fileName1, lines1);

        final stream = sut.loadPackageFile(fileName1);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            emitsError(
              isA<LoadPackageFailure>()
                  .having((f) => f.fileName, 'fileName', 'non-existent-file')
                  .having((f) => f.history, 'history', const [fileName1])
                  .having(
                    (f) => f.message,
                    'history',
                    'Package file does not exist',
                  ),
            ),
            emitsDone,
          ]),
        );
      });

      test('throws exception if circular import is detected', () {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const fileName3 = 'test-file-3';
        const lines1 = ['::import $fileName3'];
        const lines2 = ['::import $fileName1'];
        const lines3 = ['::import $fileName2'];
        writeFile(fileName1, lines1);
        writeFile(fileName2, lines2);
        writeFile(fileName3, lines3);

        final stream = sut.loadPackageFile(fileName3);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            emitsError(
              isA<LoadPackageFailure>()
                  .having((f) => f.fileName, 'fileName', fileName3)
                  .having((f) => f.history, 'history', const [
                    fileName3,
                    fileName2,
                    fileName1,
                    fileName3,
                  ])
                  .having(
                    (f) => f.message,
                    'history',
                    'Circular import detected',
                  ),
            ),
            emitsDone,
          ]),
        );
      });

      test('imports package groups', () async {
        const fileName = 'test-file';
        const groupName = 'test-group';
        const lines = ['line-A', 'line-B', 'line-C'];
        const groups = ['pkg-1', 'pkg-2', 'pkg-3'];
        writeFile(fileName, [...lines, '::group $groupName']);

        when(
          () => mockPacman.listPackagesForGroup(
            any(),
            ignoreErrors: any(named: 'ignoreErrors'),
          ),
        ).thenStream(Stream.fromIterable(groups));

        final stream = sut.loadPackageFile(fileName);

        await expectLater(
          stream,
          emitsInOrder(<dynamic>[...lines, ...groups, emitsDone]),
        );

        verify(
          () => mockPacman.listPackagesForGroup(groupName, ignoreErrors: true),
        ).called(1);
      });

      test('does not expand package groups if disabled', () async {
        const fileName = 'test-file';
        const groupName = 'test-group';
        const lines = ['line-A', 'line-B', 'line-C'];
        const groups = ['pkg-1', 'pkg-2', 'pkg-3'];
        writeFile(fileName, [...lines, '::group $groupName']);

        when(
          () => mockPacman.listPackagesForGroup(any()),
        ).thenStream(Stream.fromIterable(groups));

        final stream = sut.loadPackageFile(fileName, expandGroups: false);

        await expectLater(
          stream,
          emitsInOrder(<dynamic>[...lines, groupName, emitsDone]),
        );

        verifyNever(() => mockPacman.listPackagesForGroup(any()));
      });
    });

    group('loadPackageFileHierarchy', () {
      test('returns empty hierarchy if file does not exist', () async {
        final result = await sut.loadPackageFileHierarchy('non-existent-file');
        expect(result, PackageFileHierarchy.empty);
      });

      test('returns given filename for simple file', () async {
        const fileName = 'test-file';
        const lines = ['line-A', 'line-B', 'line-C'];
        writeFile(fileName, lines);

        final result = await sut.loadPackageFileHierarchy(fileName);
        expect(result.packageFiles, orderedEquals([fileName]));
      });

      test('imports other package files with simplified paths', () async {
        final otherDir = Directory.systemTemp.createTempSync();
        addTearDown(() async => await otherDir.delete(recursive: true));

        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        final fileName3 = otherDir.uri.resolve('test-file-3').toFilePath();
        final fileName4 = otherDir.uri.resolve('test-file-4').toFilePath();
        const fileName5 = 'test-file-5';
        const lines1_2_3_4 = ['line-A', 'line-B', 'line-C'];
        final lines5 = [
          '::import $fileName1',
          '::import ${absolute(testDir.path, fileName2)}',
          '::import $fileName3',
          '::import ${relative(fileName4, from: testDir.path)}',
        ];
        writeFile(fileName1, lines1_2_3_4);
        writeFile(fileName2, lines1_2_3_4);
        writeFile(fileName3, lines1_2_3_4);
        writeFile(fileName4, lines1_2_3_4);
        writeFile(fileName5, lines5);

        final result = await sut.loadPackageFileHierarchy(fileName5);
        expect(
          result.packageFiles,
          orderedEquals([
            fileName5,
            fileName1,
            fileName2,
            fileName3,
            fileName4,
          ]),
        );
      });

      test(
        'imports other package files recursively and keeps ordering',
        () async {
          const fileName1 = 'test-file-1';
          const fileName2 = 'test-file-2';
          const fileName3 = 'test-file-3';
          const fileName4 = 'test-file-4';
          const lines1 = ['line-A', 'line-B', 'line-C'];
          const lines2 = ['line-D', 'line-E', 'line-F'];
          const lines3 = [
            '   ::import $fileName2',
            'line-G',
            '::import $fileName1   ',
          ];
          const lines4 = ['#::import $fileName1', '::import $fileName3'];
          writeFile(fileName1, lines1);
          writeFile(fileName2, lines2);
          writeFile(fileName3, lines3);
          writeFile(fileName4, lines4);

          final result = await sut.loadPackageFileHierarchy(fileName4);
          expect(
            result.packageFiles,
            orderedEquals([fileName4, fileName3, fileName2, fileName1]),
          );
        },
      );

      test('throws exception if imported file cannot be found', () {
        const fileName1 = 'test-file';
        const lines1 = ['::import non-existent-file'];
        writeFile(fileName1, lines1);

        expect(
          () => sut.loadPackageFileHierarchy(fileName1),
          throwsA(
            isA<LoadPackageFailure>()
                .having((f) => f.fileName, 'fileName', 'non-existent-file')
                .having((f) => f.history, 'history', const [fileName1])
                .having(
                  (f) => f.message,
                  'history',
                  'Package file does not exist',
                ),
          ),
        );
      });

      test('throws exception if circular import is detected', () {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const fileName3 = 'test-file-3';
        const lines1 = ['::import $fileName3'];
        const lines2 = ['::import $fileName1'];
        const lines3 = ['::import $fileName2'];
        writeFile(fileName1, lines1);
        writeFile(fileName2, lines2);
        writeFile(fileName3, lines3);

        expect(
          () => sut.loadPackageFileHierarchy(fileName3),
          throwsA(
            isA<LoadPackageFailure>()
                .having((f) => f.fileName, 'fileName', fileName3)
                .having((f) => f.history, 'history', const [
                  fileName3,
                  fileName2,
                  fileName1,
                  fileName3,
                ])
                .having(
                  (f) => f.message,
                  'history',
                  'Circular import detected',
                ),
          ),
        );
      });

      test('collects group for packages', () async {
        const fileName = 'test-file';
        const lines = ['line-A', 'line-B', '::group test-group', 'line-C'];
        final groupLines = ['package-1', 'package-2'];
        writeFile(fileName, lines);

        when(
          () => mockPacman.listPackagesForGroup(
            any(),
            ignoreErrors: any(named: 'ignoreErrors'),
          ),
        ).thenStream(Stream.fromIterable(groupLines));

        final result = await sut.loadPackageFileHierarchy(fileName);
        expect(result.groupsByPackages, {
          'package-1': {'test-group'},
          'package-2': {'test-group'},
        });

        verify(
          () =>
              mockPacman.listPackagesForGroup('test-group', ignoreErrors: true),
        ).called(1);
      });

      test('collects multiple groups for packages', () async {
        const fileName = 'test-file';
        const lines = [
          'line-A',
          '::group test-group-2',
          'line-B',
          '::group test-group-1',
          'line-C',
        ];
        final group1Lines = ['package-1', 'package-2'];
        final group2Lines = ['package-2', 'package-3'];
        writeFile(fileName, lines);

        when(
          () => mockPacman.listPackagesForGroup(
            'test-group-1',
            ignoreErrors: any(named: 'ignoreErrors'),
          ),
        ).thenStream(Stream.fromIterable(group1Lines));
        when(
          () => mockPacman.listPackagesForGroup(
            'test-group-2',
            ignoreErrors: any(named: 'ignoreErrors'),
          ),
        ).thenStream(Stream.fromIterable(group2Lines));

        final result = await sut.loadPackageFileHierarchy(fileName);
        expect(result.groupsByPackages, {
          'package-1': {'test-group-1'},
          'package-2': orderedEquals(['test-group-2', 'test-group-1']),
          'package-3': {'test-group-2'},
        });

        verifyInOrder([
          () => mockPacman.listPackagesForGroup(
            'test-group-2',
            ignoreErrors: true,
          ),
          () => mockPacman.listPackagesForGroup(
            'test-group-1',
            ignoreErrors: true,
          ),
        ]);
      });
    });

    group('ensurePackageFileExists', () {
      const testMachineName = 'ensurePackageFileExists-machine';
      test('creates file if it does not exist', () async {
        final now = DateTime.now();
        await Future<void>.delayed(const Duration(seconds: 1));

        await sut.ensurePackageFileExists(testMachineName);

        expect(packageFile(testMachineName).existsSync(), isTrue);
        expect(
          packageFile(testMachineName).lastModifiedSync().isAfter(now),
          isTrue,
        );
      });

      test('does nothing if file already exist', () async {
        final createdFile = await packageFile(testMachineName).create();
        final createdTimeStamp = createdFile.lastModifiedSync();
        await Future<void>.delayed(const Duration(seconds: 1));

        await sut.ensurePackageFileExists(testMachineName);

        expect(packageFile(testMachineName).existsSync(), isTrue);
        expect(
          packageFile(testMachineName).lastModifiedSync(),
          createdTimeStamp,
        );
      });
    });

    group('addToPackageFile', () {
      test('creates new file with single entry if it does not exist', () async {
        const testMachineName = 'test-machine';
        const testPackageName = 'test-package';

        await sut.addToPackageFile(testMachineName, testPackageName);

        expect(testDir.listSync(), hasLength(1));
        final testFile = packageFile(testMachineName);
        expect(testFile.existsSync(), isTrue);
        expect(testFile.readAsLinesSync(), const [testPackageName]);
      });

      test('appends single entry to existing file', () async {
        const testMachineName = 'test-machine';
        const testPackageName = 'test-package';
        const existingPackages = ['line1', 'line2', 'line3'];

        final testFile = packageFile(testMachineName);
        await testFile.writeAsString('${existingPackages.join('\n')}\n');

        await sut.addToPackageFile(testMachineName, testPackageName);

        expect(testDir.listSync(), hasLength(1));
        expect(testFile.existsSync(), isTrue);
        expect(testFile.readAsLinesSync(), const [
          ...existingPackages,
          testPackageName,
        ]);
      });
    });

    group('removeFromPackageFile', () {
      const testPackageName = 'test-package';

      test('returns false if file does not exist', () async {
        final result = await sut.removeFromPackageFile(
          'non-existent-file',
          testPackageName,
        );

        expect(result, isFalse);
      });

      test('returns false if package is not found within file', () async {
        const fileName = 'test-file';
        const lines = ['line-A', 'line-B', 'line-C'];
        writeFile(fileName, lines);

        final result = await sut.removeFromPackageFile(
          fileName,
          testPackageName,
        );

        expect(result, isFalse);
        expect(packageFile(fileName).readAsLinesSync(), lines);
      });

      test('removes line from file and returns true', () async {
        const fileName = 'test-file';
        const lines = ['line-A', testPackageName, 'line-C'];
        writeFile(fileName, lines);

        final result = await sut.removeFromPackageFile(
          fileName,
          testPackageName,
        );

        expect(result, isTrue);
        expect(packageFile(fileName).readAsLinesSync(), [lines[0], lines[2]]);
      });

      test('keeps comment, group and empty lines', () async {
        const fileName = 'test-file';
        const lines = [
          '# $testPackageName',
          '',
          '    # $testPackageName',
          '::group $testPackageName',
          '  \t    ',
          '   $testPackageName     ',
        ];
        writeFile(fileName, lines);

        final result = await sut.removeFromPackageFile(
          fileName,
          testPackageName,
        );

        expect(result, isTrue);
        expect(packageFile(fileName).readAsLinesSync(), lines.sublist(0, 5));

        verifyNever(() => mockPacman.listPackagesForGroup(any()));
      });

      test(
        'removes group instead of normal line if set and returns true',
        () async {
          const fileName = 'test-file';
          const lines = [
            'line-A',
            testPackageName,
            '::group $testPackageName',
            testPackageName,
            'line-C',
          ];
          writeFile(fileName, lines);

          final result = await sut.removeFromPackageFile(
            fileName,
            testPackageName,
            isGroup: true,
          );

          expect(result, isTrue);
          expect(packageFile(fileName).readAsLinesSync(), [
            lines[0],
            lines[1],
            lines[3],
            lines[4],
          ]);
        },
      );

      test('replaces removed lines if replacements are given', () async {
        const fileName = 'test-file';
        const lines = ['line-A', testPackageName, 'line-C'];
        const replacements = ['line-X', 'line-Y'];
        writeFile(fileName, lines);

        final result = await sut.removeFromPackageFile(
          fileName,
          testPackageName,
          replacement: replacements,
        );

        expect(result, isTrue);
        expect(packageFile(fileName).readAsLinesSync(), [
          lines[0],
          lines[2],
          ...replacements,
        ]);
      });

      test('searches package files recursively', () async {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const fileName3 = 'test-file-3';
        const lines1 = ['line-A', 'line-B', 'line-C', testPackageName];
        const lines2 = ['::import $fileName1', testPackageName];
        const lines3 = ['::import $fileName2'];
        writeFile(fileName1, lines1);
        writeFile(fileName2, lines2);
        writeFile(fileName3, lines3);

        final result = await sut.removeFromPackageFile(
          fileName3,
          testPackageName,
        );

        expect(result, isTrue);
        expect(packageFile(fileName3).readAsLinesSync(), lines3);
        expect(packageFile(fileName2).readAsLinesSync(), lines2);
        expect(packageFile(fileName1).readAsLinesSync(), lines1.sublist(0, 3));
      });

      test('does not search package files recursively if disabled', () async {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const lines1 = ['line-A', 'line-B', 'line-C', testPackageName];
        const lines2 = ['::import $fileName1', testPackageName];
        writeFile(fileName1, lines1);
        writeFile(fileName2, lines2);

        final result = await sut.removeFromPackageFile(
          fileName2,
          testPackageName,
          recursive: false,
        );

        expect(result, isTrue);
        expect(packageFile(fileName2).readAsLinesSync(), lines2.sublist(0, 1));
        expect(packageFile(fileName1).readAsLinesSync(), lines1);
      });

      test('throws exception if imported file cannot be found', () {
        const fileName1 = 'test-file';
        const lines1 = ['::import non-existent-file'];
        writeFile(fileName1, lines1);

        expect(
          () => sut.removeFromPackageFile(fileName1, testPackageName),
          throwsA(
            isA<LoadPackageFailure>()
                .having((f) => f.fileName, 'fileName', 'non-existent-file')
                .having((f) => f.history, 'history', const [fileName1])
                .having(
                  (f) => f.message,
                  'history',
                  'Package file does not exist',
                ),
          ),
        );
      });

      test('throws exception if circular import is detected', () {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const fileName3 = 'test-file-3';
        const lines1 = ['::import $fileName3'];
        const lines2 = ['::import $fileName1'];
        const lines3 = ['::import $fileName2'];
        writeFile(fileName1, lines1);
        writeFile(fileName2, lines2);
        writeFile(fileName3, lines3);

        expect(
          () => sut.removeFromPackageFile(fileName3, testPackageName),
          throwsA(
            isA<LoadPackageFailure>()
                .having((f) => f.fileName, 'fileName', fileName3)
                .having((f) => f.history, 'history', const [
                  fileName3,
                  fileName2,
                  fileName1,
                  fileName3,
                ])
                .having(
                  (f) => f.message,
                  'history',
                  'Circular import detected',
                ),
          ),
        );
      });
    });
  });
}
