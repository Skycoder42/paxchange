// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

part 'aur_options.freezed.dart';
part 'aur_options.g.dart';

@freezed
class PubspecWithAur with _$PubspecWithAur {
  const factory PubspecWithAur({
    required Pubspec pubspec,
    required AurOptions aurOptions,
    required Map<String, String?> executables,
  }) = _PubspecWithAur;
}

@freezed
class AurOptionsPubspecView with _$AurOptionsPubspecView {
  @JsonSerializable(
    anyMap: true,
    checked: true,
  )
  const factory AurOptionsPubspecView({
    required Map<String, String?> executables,
    required AurOptions aur,
  }) = _AurOptionsPubspecView;

  factory AurOptionsPubspecView.fromJson(Map<String, dynamic> json) =>
      _$AurOptionsPubspecViewFromJson(json);

  factory AurOptionsPubspecView.fromYaml(Map? map) =>
      AurOptionsPubspecView.fromJson(Map<String, dynamic>.from(map!));
}

@freezed
class AurOptions with _$AurOptions {
  @JsonSerializable(
    anyMap: true,
    checked: true,
    disallowUnrecognizedKeys: true,
  )
  const factory AurOptions({
    required String maintainer,
    @Default('1') String pkgrel,
    @Default('custom') String license,
    @Default(<String>[]) List<String> depends,
  }) = _AurOptions;

  factory AurOptions.fromJson(Map<String, dynamic> json) =>
      _$AurOptionsFromJson(json);
}
