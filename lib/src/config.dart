import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'util/directory_json_converter.dart';

part 'config.freezed.dart';
part 'config.g.dart';

// coverage:ignore-start
@riverpod
Config config(Ref ref) =>
    throw StateError('configProvider must be overridden with a valid config');
// coverage:ignore-end

@freezed
sealed class Config with _$Config {
  @DirectoryJsonConverter()
  const factory Config({
    required Directory storageDirectory,
    String? machineName,
    String? pacmanFrontend,
  }) = _Config;

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  const Config._();

  String get rootPackageFile => machineName ?? Platform.localHostname;
}
