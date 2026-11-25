import 'package:freezed_annotation/freezed_annotation.dart';

part 'diff_entry.freezed.dart';

class DecodingFailure(final String line) implements Exception {
  @override
  String toString() => '"$line"is not a diff entry. Must start with + or -';
}

@freezed
sealed class const DiffEntry._()
    with _$DiffEntry
    implements Comparable<DiffEntry> {
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
