import 'package:freezed_annotation/freezed_annotation.dart';

part 'package_file_hierarchy.freezed.dart';

@freezed
sealed class PackageFileHierarchy with _$PackageFileHierarchy {
  static const empty = PackageFileHierarchy(
    packageFiles: {},
    groupsByPackages: {},
  );

  const factory PackageFileHierarchy({
    required Set<String> packageFiles,
    required Map<String, Set<String>> groupsByPackages,
    @Default({}) Set<String> missingGroups,
  }) = _PackageFileHierarchy;
}
