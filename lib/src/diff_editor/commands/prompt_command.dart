import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

enum PromptResult({
  required final bool stopProcessing,
  required final bool didModify,
}) {
  succeeded(stopProcessing: false, didModify: true),
  succeededReload(stopProcessing: true, didModify: true),
  failed(stopProcessing: true, didModify: true),
  repeat(stopProcessing: false, didModify: false),
  skipped(stopProcessing: false, didModify: false),
  quit(stopProcessing: true, didModify: false);

  PromptResult withReload() => switch (this) {
    PromptResult.succeeded => PromptResult.succeededReload,
    _ => this,
  };
}

abstract base class const PromptCommand(
  @protected final Console console,
  final String packageName,
) {
  String get key;
  String get description;

  FutureOr<PromptResult> call();
}
