// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package_info_converters.dart';

part 'package_info.freezed.dart';
part 'package_info.g.dart';

@freezed
class LocalPackageInfo with _$LocalPackageInfo {
  @PackageInfoStringListConvert()
  @PackageInfoIntConverter()
  @PackageInfoDoubleConverter()
  const factory LocalPackageInfo({
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Version') required String version,
    @JsonKey(name: 'Description') required String description,
    @JsonKey(name: 'URL') required Uri url,
    @JsonKey(name: 'Licenses') required List<String> licenses,
    @JsonKey(name: 'Groups') required List<String> groups,
    @JsonKey(name: 'Provides') required List<String> provides,
    @JsonKey(name: 'Depends On') required List<String> dependsOn,
    @JsonKey(name: 'Optional Deps') required List<String> optionalDeps,
    @JsonKey(name: 'Required By') required List<String> requiredBy,
    @JsonKey(name: 'Optional For') required List<String> optionalFor,
    @JsonKey(name: 'Conflicts With') required List<String> conflictsWith,
    @JsonKey(name: 'Replaces') required List<String> replaces,
    @JsonKey(name: 'Install Date') required String installDate,
    @JsonKey(name: 'Install Reason') required String installReason,
  }) = _LocalPackageInfo;

  factory LocalPackageInfo.fromJson(Map<String, dynamic> json) =>
      _$LocalPackageInfoFromJson(json);

  factory LocalPackageInfo.parse(List<String> lines) =>
      LocalPackageInfo.fromJson(
        Map<String, dynamic>.fromEntries(lines.map(_parseLine)),
      );
}

@freezed
class RemotePackageInfo with _$RemotePackageInfo {
  const RemotePackageInfo._();

  @PackageInfoStringListConvert()
  @PackageInfoIntConverter()
  @PackageInfoDoubleConverter()
  // ignore: sort_unnamed_constructors_first
  const factory RemotePackageInfo({
    @JsonKey(name: 'Repository') required String repository,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Keywords') @Default(<String>[]) List<String> keywords,
    @JsonKey(name: 'Version') required String version,
    @JsonKey(name: 'Description') required String description,
    @JsonKey(name: 'URL') required Uri url,
    @JsonKey(name: 'AUR URL') Uri? aurUrl,
    @JsonKey(name: 'Licenses') required List<String> licenses,
    @JsonKey(name: 'Groups') required List<String> groups,
    @JsonKey(name: 'Provides') required List<String> provides,
    @JsonKey(name: 'Depends On') required List<String> dependsOn,
    @JsonKey(name: 'Optional Deps') required List<String> optionalDeps,
    @JsonKey(name: 'Conflicts With') required List<String> conflictsWith,
    @JsonKey(name: 'Replaces') required List<String> replaces,
    @JsonKey(name: 'Maintainer') String? maintainer,
    @JsonKey(name: 'Votes') int? votes,
    @JsonKey(name: 'Popularity') double? popularity,
    @JsonKey(name: 'First Submitted') String? firstSubmitted,
    @JsonKey(name: 'Last Modified') String? lastModified,
    @JsonKey(name: 'Out-of-date') String? outOfDate,
  }) = _RemotePackageInfo;

  factory RemotePackageInfo.fromJson(Map<String, dynamic> json) =>
      _$RemotePackageInfoFromJson(json);

  factory RemotePackageInfo.parse(List<String> lines) =>
      RemotePackageInfo.fromJson(
        Map<String, dynamic>.fromEntries(lines.map(_parseLine)),
      );

  bool get isAurPackage => repository == 'aur';
}

MapEntry<String, String> _parseLine(String line) {
  final firstColon = line.indexOf(':');
  if (firstColon == -1) {
    return MapEntry(line, '');
  }

  return MapEntry(
    line.substring(0, firstColon).trim(),
    line.substring(firstColon + 1).trim(),
  );
}
