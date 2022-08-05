import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

abstract class PromptCommand {
  const PromptCommand();

  String get key;
  String get description;

  FutureOr<bool> call(Console console, String packageName);

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
