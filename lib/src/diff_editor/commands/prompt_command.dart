import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

enum PromptResult {
  succeeded(stopProcessing: false, didModify: true),
  failed(stopProcessing: true, didModify: true),
  repeat(stopProcessing: false, didModify: false),
  skipped(stopProcessing: false, didModify: false),
  quit(stopProcessing: true, didModify: false);

  final bool stopProcessing;
  final bool didModify;

  const PromptResult({
    required this.stopProcessing,
    required this.didModify,
  });
}

abstract class PromptCommand {
  const PromptCommand();

  String get key;
  String get description;

  FutureOr<PromptResult> call(Console console, String packageName);

  @nonVirtual
  void writeOption(Console console) {
    console
      ..write('  ')
      ..setForegroundColor(ConsoleColor.blue)
      ..write(key)
      ..resetColorAttributes()
      ..write(': $description\n');
  }
}
