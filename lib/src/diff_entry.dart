import 'package:freezed_annotation/freezed_annotation.dart';

part 'diff_entry.freezed.dart';

class DecodingFailure implements Exception {
  final String line;

  new(this.line);

  @override
  String toString() => '"$line"is not a diff entry. Must start with + or -';
}

@freezed
sealed class DiffEntry with _$DiffEntry implements Comparable<DiffEntry> {
  const new _();

  const factory added(String package) = DiffAddedEntry;
  const factory removed(String package) = DiffRemovedEntry;

  factory decode(String line) {
    switch (line.substring(0, 1)) {
      case '+':
        return DiffEntry.added(line.substring(1));
      case '-':
        return DiffEntry.removed(line.substring(1));
      default:
        throw DecodingFailure(line);
    }
  }

  String encode() => switch (this) {
    DiffAddedEntry(:final package) => '+$package',
    DiffRemovedEntry(:final package) => '-$package',
  };

  @override
  int compareTo(DiffEntry other) => package.compareTo(other.package);
}
