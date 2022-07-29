import 'dart:io';

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

    void _writeFile(String name, List<String> lines) =>
        File.fromUri(testDir.uri.resolve(name))
            .writeAsStringSync(lines.join('\n'));

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
  });
}
