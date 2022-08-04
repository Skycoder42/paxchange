// coverage:ignore-file

import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

import 'util/directory_json_converter.dart';

part 'config.freezed.dart';
part 'config.g.dart';

final configProvider = Provider<Config>(
  (ref) => throw StateError(
    'configProvider must be overridden with a valid config',
  ),
);

@freezed
class Config with _$Config {
  const Config._();

  @DirectoryJsonConverter()
  // ignore: sort_unnamed_constructors_first
  const factory Config({
    required Directory storageDirectory,
    String? machineName,
    String? pacmanFrontend,
  }) = _Config;

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  String get rootPackageFile => machineName ?? Platform.localHostname;
}
