import 'package:dart_test_tools/test.dart';
import 'package:paxchange/src/diff_entry.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

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
    testData<Tuple2<DiffEntry, String>>(
      'encode and decode work as expected',
      const [
        Tuple2(DiffEntry.added('package'), '+package'),
        Tuple2(DiffEntry.removed('package'), '-package'),
      ],
      (fixture) {
        expect(fixture.item1.encode(), fixture.item2);
        expect(DiffEntry.decode(fixture.item2), fixture.item1);
      },
    );

    test('decode throws exception if line is not a valid diff entry', () {
      const line = 'invalid-line';

      expect(
        () => DiffEntry.decode(line),
        throwsA(isA<DecodingFailure>().having((f) => f.line, 'line', line)),
      );
    });

    testData<Tuple3<DiffEntry, DiffEntry, int>>(
      'compareTo correctly orders diff entries',
      [
        const Tuple3(DiffEntry.added('a'), DiffEntry.added('a'), 0),
        const Tuple3(DiffEntry.added('a'), DiffEntry.added('b'), -1),
        const Tuple3(DiffEntry.added('b'), DiffEntry.added('a'), 1),
        const Tuple3(DiffEntry.removed('a'), DiffEntry.removed('a'), 0),
        const Tuple3(DiffEntry.removed('a'), DiffEntry.removed('b'), -1),
        const Tuple3(DiffEntry.removed('b'), DiffEntry.removed('a'), 1),
        const Tuple3(DiffEntry.added('a'), DiffEntry.removed('a'), 0),
        const Tuple3(DiffEntry.added('a'), DiffEntry.removed('b'), -1),
        const Tuple3(DiffEntry.added('b'), DiffEntry.removed('a'), 1),
      ],
      (fixture) {
        expect(fixture.item1.compareTo(fixture.item2), fixture.item3);
      },
    );
  });
}
