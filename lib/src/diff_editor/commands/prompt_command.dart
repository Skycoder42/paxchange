import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

enum PromptResult {
  succeeded(stopProcessing: false, didModify: true),
  succeededReload(stopProcessing: true, didModify: true),
  failed(stopProcessing: true, didModify: true),
  repeat(stopProcessing: false, didModify: false),
  skipped(stopProcessing: false, didModify: false),
  quit(stopProcessing: true, didModify: false);

  final bool stopProcessing;
  final bool didModify;

  const PromptResult({required this.stopProcessing, required this.didModify});

  PromptResult withReload() => switch (this) {
    PromptResult.succeeded => PromptResult.succeededReload,
    _ => this,
  };
}

abstract base class PromptCommand {
  @protected
  final Console console;
  final String packageName;

  const PromptCommand(this.console, this.packageName);

  String get key;
  String get description;

  FutureOr<PromptResult> call();
}
