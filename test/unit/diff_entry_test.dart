import 'package:dart_test_tools/test.dart';
import 'package:paxchange/src/diff_entry.dart';
import 'package:test/test.dart';

void main() {
  group('$DecodingFailure', () {
    test('toString generates correct message', () {
      final error = DecodingFailure('test-line');

      expect(
        error.toString(),
        '"test-line"is not a diff entry. Must start with + or -',
      );
    });
  });

  group('$DiffEntry', () {
    testData<(DiffEntry, String)>(
      'encode and decode work as expected',
      const [
        (DiffEntry.added('package'), '+package'),
        (DiffEntry.removed('package'), '-package'),
      ],
      (fixture) {
        expect(fixture.$1.encode(), fixture.$2);
        expect(DiffEntry.decode(fixture.$2), fixture.$1);
      },
    );

    test('decode throws exception if line is not a valid diff entry', () {
      const line = 'invalid-line';

      expect(
        () => DiffEntry.decode(line),
        throwsA(isA<DecodingFailure>().having((f) => f.line, 'line', line)),
      );
    });

    testData<(DiffEntry, DiffEntry, int)>(
      'compareTo correctly orders diff entries',
      const [
        (DiffEntry.added('a'), DiffEntry.added('a'), 0),
        (DiffEntry.added('a'), DiffEntry.added('b'), -1),
        (DiffEntry.added('b'), DiffEntry.added('a'), 1),
        (DiffEntry.removed('a'), DiffEntry.removed('a'), 0),
        (DiffEntry.removed('a'), DiffEntry.removed('b'), -1),
        (DiffEntry.removed('b'), DiffEntry.removed('a'), 1),
        (DiffEntry.added('a'), DiffEntry.removed('a'), 0),
        (DiffEntry.added('a'), DiffEntry.removed('b'), -1),
        (DiffEntry.added('b'), DiffEntry.removed('a'), 1),
      ],
      (fixture) {
        expect(fixture.$1.compareTo(fixture.$2), fixture.$3);
      },
    );
  });
}
