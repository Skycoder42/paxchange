import 'dart:io';

import 'package:paxchange/src/diff_entry.dart';
import 'package:paxchange/src/storage/diff_file_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('$DiffFileAdapter', () {
    late Directory testDir;

    late DiffFileAdapter sut;

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();

      sut = DiffFileAdapter(testDir);
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    void _writeFile(String name, Iterable<String> lines) =>
        File.fromUri(testDir.uri.resolve('$name.pcs'))
            .writeAsStringSync(lines.join('\n'));

    group('hasPackageDiff', () {
      test('returns false if file does not exist', () {
        expect(sut.hasPackageDiff('non-existent-file'), isFalse);
      });

      test('returns true if file does exist', () {
        const fileName = 'existent-file';
        _writeFile(fileName, const []);

        expect(sut.hasPackageDiff(fileName), isTrue);
      });
    });

    group('loadPackageDiff', () {
      test('returns empty stream if file does not exist', () {
        final stream = sut.loadPackageDiff('non-existent-file');
        expect(stream, emitsDone);
      });

      test('returns diff list if file does exist', () {
        const fileName = 'test-file';
        const diffEntries = [
          DiffEntry.added('line1'),
          DiffEntry.added('line2'),
          DiffEntry.removed('line3'),
          DiffEntry.added('line4'),
          DiffEntry.removed('line5'),
        ];
        _writeFile(fileName, diffEntries.map((e) => e.encode()));

        final stream = sut.loadPackageDiff(fileName);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            ...diffEntries,
            emitsDone,
          ]),
        );
      });

      test('throws exception if diff contains invalid data', () {
        const fileName = 'test-file';
        _writeFile(fileName, const ['invalid-entry']);

        final stream = sut.loadPackageDiff(fileName);
        expect(
          stream,
          emitsInOrder(<dynamic>[
            emitsError(isA<DecodingFailure>()),
            emitsDone,
          ]),
        );
      });
    });

    group('savePackageDiff', () {
      test('does nothing if diff is empty and no files exist', () async {
        const fileName = 'test-file';

        await sut.savePackageDiff(fileName, const {});

        expect(testDir.listSync(), isEmpty);
      });

      test('deletes file if diff is empty and files exist', () async {
        const fileName = 'test-file';
        _writeFile(fileName, const []);

        await sut.savePackageDiff(fileName, const {});

        expect(testDir.listSync(), isEmpty);
      });

      test('writes diff file with changes and replaces existing file',
          () async {
        const fileName = 'test-file';
        final diffEntries = {
          const DiffEntry.added('line1'),
          const DiffEntry.added('line2'),
          const DiffEntry.removed('line3'),
          const DiffEntry.added('line4'),
          const DiffEntry.removed('line5'),
        };
        _writeFile(fileName, const []);

        await sut.savePackageDiff(fileName, diffEntries);

        expect(testDir.listSync(), hasLength(1));

        final testFile = File.fromUri(testDir.uri.resolve('$fileName.pcs'));
        expect(testFile.existsSync(), isTrue);

        expect(
          testFile.readAsLinesSync(),
          unorderedEquals(diffEntries.map<String>((e) => e.encode())),
        );
      });
    });
  });
}
