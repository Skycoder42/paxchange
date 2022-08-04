import 'dart:io';

import 'package:path/path.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:test/test.dart';

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
    late Directory testDir;

    late PackageFileAdapter sut;

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();

      sut = PackageFileAdapter(testDir);
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    File _packageFile(String name) => File.fromUri(testDir.uri.resolve(name));

    void _writeFile(String name, List<String> lines) =>
        _packageFile(name).writeAsStringSync(lines.join('\n'));

    group('loadPackageFile', () {
      test('returns empty stream if file does not exist', () {
        final stream = sut.loadPackageFile('non-existent-file');
        expect(stream, emitsDone);
      });

      test('returns lines of a simple file', () {
        const fileName = 'test-file';
        const lines = [
          'line-A',
          'line-B',
          'line-C',
        ];
        _writeFile(fileName, lines);

        final stream = sut.loadPackageFile(fileName);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            ...lines,
            emitsDone,
          ]),
        );
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
        _writeFile(fileName, lines);

        final stream = sut.loadPackageFile(fileName);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            lines.first.trim(),
            emitsDone,
          ]),
        );
      });

      test('imports other package files', () {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const lines1 = [
          'line-A',
          'line-B',
          'line-C',
        ];
        const lines2 = ['::import $fileName1'];
        _writeFile(fileName1, lines1);
        _writeFile(fileName2, lines2);

        final stream = sut.loadPackageFile(fileName2);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            ...lines1,
            emitsDone,
          ]),
        );
      });

      test('imports other package files recursively and keeps ordering', () {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const fileName3 = 'test-file-3';
        const fileName4 = 'test-file-4';
        const lines1 = [
          'line-A',
          'line-B',
          'line-C',
        ];
        const lines2 = [
          'line-D',
          'line-E',
          'line-F',
        ];
        const lines3 = [
          '   ::import $fileName2',
          'line-G',
          '::import $fileName1   ',
        ];
        const lines4 = [
          '#::import $fileName1',
          '::import $fileName3',
        ];
        _writeFile(fileName1, lines1);
        _writeFile(fileName2, lines2);
        _writeFile(fileName3, lines3);
        _writeFile(fileName4, lines4);

        final stream = sut.loadPackageFile(fileName4);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            ...lines2,
            lines3[1],
            ...lines1,
            emitsDone,
          ]),
        );
      });

      test('throws exception if imported file cannot be found', () {
        const fileName1 = 'test-file';
        const lines1 = ['::import non-existent-file'];
        _writeFile(fileName1, lines1);

        final stream = sut.loadPackageFile(fileName1);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            emitsError(
              isA<LoadPackageFailure>()
                  .having(
                (f) => f.fileName,
                'fileName',
                'non-existent-file',
              )
                  .having(
                (f) => f.history,
                'history',
                const [fileName1],
              ).having(
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
        _writeFile(fileName1, lines1);
        _writeFile(fileName2, lines2);
        _writeFile(fileName3, lines3);

        final stream = sut.loadPackageFile(fileName3);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            emitsError(
              isA<LoadPackageFailure>()
                  .having(
                (f) => f.fileName,
                'fileName',
                fileName3,
              )
                  .having(
                (f) => f.history,
                'history',
                const [fileName3, fileName2, fileName1, fileName3],
              ).having(
                (f) => f.message,
                'history',
                'Circular import detected',
              ),
            ),
            emitsDone,
          ]),
        );
      });
    });

    group('loadPackageFileHierarchy', () {
      test('returns empty stream if file does not exist', () {
        final stream = sut.loadPackageFileHierarchy('non-existent-file');
        expect(stream, emitsDone);
      });

      test('returns given filename for simple file', () {
        const fileName = 'test-file';
        const lines = [
          'line-A',
          'line-B',
          'line-C',
        ];
        _writeFile(fileName, lines);

        final stream = sut.loadPackageFileHierarchy(fileName);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            fileName,
            emitsDone,
          ]),
        );
      });

      test('imports other package files with simplified paths', () {
        final otherDir = Directory.systemTemp.createTempSync();
        addTearDown(() => otherDir.delete(recursive: true));

        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        final fileName3 = otherDir.uri.resolve('test-file-3').toFilePath();
        final fileName4 = otherDir.uri.resolve('test-file-4').toFilePath();
        const fileName5 = 'test-file-5';
        const lines1_2_3_4 = [
          'line-A',
          'line-B',
          'line-C',
        ];
        final lines5 = [
          '::import $fileName1',
          '::import ${absolute(testDir.path, fileName2)}',
          '::import $fileName3',
          '::import ${relative(fileName4, from: testDir.path)}',
        ];
        _writeFile(fileName1, lines1_2_3_4);
        _writeFile(fileName2, lines1_2_3_4);
        _writeFile(fileName3, lines1_2_3_4);
        _writeFile(fileName4, lines1_2_3_4);
        _writeFile(fileName5, lines5);

        final stream = sut.loadPackageFileHierarchy(fileName5);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            fileName5,
            fileName1,
            fileName2,
            fileName3,
            fileName4,
            emitsDone,
          ]),
        );
      });

      test('imports other package files recursively and keeps ordering', () {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const fileName3 = 'test-file-3';
        const fileName4 = 'test-file-4';
        const lines1 = [
          'line-A',
          'line-B',
          'line-C',
        ];
        const lines2 = [
          'line-D',
          'line-E',
          'line-F',
        ];
        const lines3 = [
          '   ::import $fileName2',
          'line-G',
          '::import $fileName1   ',
        ];
        const lines4 = [
          '#::import $fileName1',
          '::import $fileName3',
        ];
        _writeFile(fileName1, lines1);
        _writeFile(fileName2, lines2);
        _writeFile(fileName3, lines3);
        _writeFile(fileName4, lines4);

        final stream = sut.loadPackageFileHierarchy(fileName4);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            fileName4,
            fileName3,
            fileName2,
            fileName1,
            emitsDone,
          ]),
        );
      });

      test('throws exception if imported file cannot be found', () {
        const fileName1 = 'test-file';
        const lines1 = ['::import non-existent-file'];
        _writeFile(fileName1, lines1);

        final stream = sut.loadPackageFileHierarchy(fileName1);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            fileName1,
            emitsError(
              isA<LoadPackageFailure>()
                  .having(
                (f) => f.fileName,
                'fileName',
                'non-existent-file',
              )
                  .having(
                (f) => f.history,
                'history',
                const [fileName1],
              ).having(
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
        _writeFile(fileName1, lines1);
        _writeFile(fileName2, lines2);
        _writeFile(fileName3, lines3);

        final stream = sut.loadPackageFileHierarchy(fileName3);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            fileName3,
            fileName2,
            fileName1,
            emitsError(
              isA<LoadPackageFailure>()
                  .having(
                (f) => f.fileName,
                'fileName',
                fileName3,
              )
                  .having(
                (f) => f.history,
                'history',
                const [fileName3, fileName2, fileName1, fileName3],
              ).having(
                (f) => f.message,
                'history',
                'Circular import detected',
              ),
            ),
            emitsDone,
          ]),
        );
      });
    });

    group('addToPackageFile', () {
      test('creates new file with single entry if it does not exist', () async {
        const testMachineName = 'test-machine';
        const testPackageName = 'test-package';

        await sut.addToPackageFile(testMachineName, testPackageName);

        expect(testDir.listSync(), hasLength(1));
        final testFile = _packageFile(testMachineName);
        expect(testFile.existsSync(), isTrue);
        expect(testFile.readAsLinesSync(), const [testPackageName]);
      });

      test('appends single entry to existing file', () async {
        const testMachineName = 'test-machine';
        const testPackageName = 'test-package';
        const existingPackages = [
          'line1',
          'line2',
          'line3',
        ];

        final testFile = _packageFile(testMachineName);
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
        const lines = [
          'line-A',
          'line-B',
          'line-C',
        ];
        _writeFile(fileName, lines);

        final result = await sut.removeFromPackageFile(
          fileName,
          testPackageName,
        );

        expect(result, isFalse);
        expect(_packageFile(fileName).readAsLinesSync(), lines);
      });

      test('removes line from file and returns true', () async {
        const fileName = 'test-file';
        const lines = [
          'line-A',
          testPackageName,
          'line-C',
        ];
        _writeFile(fileName, lines);

        final result = await sut.removeFromPackageFile(
          fileName,
          testPackageName,
        );

        expect(result, isTrue);
        expect(
          _packageFile(fileName).readAsLinesSync(),
          [lines[0], lines[2]],
        );
      });

      test('skips comment and empty lines', () async {
        const fileName = 'test-file';
        const lines = [
          '# $testPackageName',
          '',
          '    # $testPackageName',
          '  \t    ',
          '   $testPackageName     ',
        ];
        _writeFile(fileName, lines);

        final result = await sut.removeFromPackageFile(
          fileName,
          testPackageName,
        );

        expect(result, isTrue);
        expect(_packageFile(fileName).readAsLinesSync(), lines.sublist(0, 4));
      });

      test('searches package files recursively', () async {
        const fileName1 = 'test-file-1';
        const fileName2 = 'test-file-2';
        const fileName3 = 'test-file-3';
        const lines1 = [
          'line-A',
          'line-B',
          'line-C',
          testPackageName,
        ];
        const lines2 = [
          '::import $fileName1',
          testPackageName,
        ];
        const lines3 = ['::import $fileName2'];
        _writeFile(fileName1, lines1);
        _writeFile(fileName2, lines2);
        _writeFile(fileName3, lines3);

        final result = await sut.removeFromPackageFile(
          fileName3,
          testPackageName,
        );

        expect(result, isTrue);
        expect(_packageFile(fileName3).readAsLinesSync(), lines3);
        expect(_packageFile(fileName2).readAsLinesSync(), lines2);
        expect(_packageFile(fileName1).readAsLinesSync(), lines1.sublist(0, 3));
      });

      test('throws exception if imported file cannot be found', () {
        const fileName1 = 'test-file';
        const lines1 = ['::import non-existent-file'];
        _writeFile(fileName1, lines1);

        expect(
          () => sut.removeFromPackageFile(fileName1, testPackageName),
          throwsA(
            isA<LoadPackageFailure>()
                .having(
              (f) => f.fileName,
              'fileName',
              'non-existent-file',
            )
                .having(
              (f) => f.history,
              'history',
              const [fileName1],
            ).having(
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
        _writeFile(fileName1, lines1);
        _writeFile(fileName2, lines2);
        _writeFile(fileName3, lines3);

        expect(
          () => sut.removeFromPackageFile(fileName3, testPackageName),
          throwsA(
            isA<LoadPackageFailure>()
                .having(
              (f) => f.fileName,
              'fileName',
              fileName3,
            )
                .having(
              (f) => f.history,
              'history',
              const [fileName3, fileName2, fileName1, fileName3],
            ).having(
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
