// coverage:ignore-file

import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

part 'config.freezed.dart';

final configProvider = Provider<Config>(
  (ref) => throw StateError(
    'configProvider must be overridden with a valid config',
  ),
);

@freezed
class Config with _$Config {
  const factory Config({
    required Directory storageDirectory,
    String? queryPackagesTool,
  }) = _Config;
}
