import 'package:freezed_annotation/freezed_annotation.dart';

part 'diff_entry.freezed.dart';

@freezed
class DiffEntry with _$DiffEntry implements Comparable<DiffEntry> {
  const DiffEntry._();

  const factory DiffEntry.added(String package) = _Added;
  const factory DiffEntry.removed(String package) = _Removed;

  factory DiffEntry.decode(String line) {
    switch (line.substring(0, 1)) {
      case '+':
        return DiffEntry.added(line.substring(1));
      case '-':
        return DiffEntry.removed(line.substring(1));
      default:
        throw ArgumentError.value(
          line,
          'line',
          'is not a diff entry. Must start with + or -',
        );
    }
  }

  String encode() => when(
        added: (package) => '+$package',
        removed: (package) => '-$package',
      );

  @override
  int compareTo(DiffEntry other) => package.compareTo(other.package);
}
