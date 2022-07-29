import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

abstract class PromptCommand {
  const PromptCommand();

  String get key;
  String get description;

  @nonVirtual
  void writeOption(Console console) {
    console
      ..write('  ')
      ..setForegroundColor(ConsoleColor.blue)
      ..write(key)
      ..resetColorAttributes()
      ..write(': $description\n');
  }

  FutureOr<bool> call(Console console, String packageName);

  @protected
  static void writeError(Console console, String message) {
    console
      ..setForegroundColor(ConsoleColor.red)
      ..writeLine()
      ..writeErrorLine(message)
      ..resetColorAttributes();
  }

  static FutureOr<bool> prompt(
    Console console,
    String packageName,
    List<PromptCommand> commands,
  ) {
    while (true) {
      console.writeLine('What do you want to do?');
      for (final command in commands) {
        command.writeOption(console);
      }

      console
        ..write('> ')
        ..setTextStyle(blink: true);
      final key = console.readKey();
      console.setTextStyle();

      for (final command in commands) {
        if (command.key == key.char) {
          return command(console, packageName);
        }
      }

      writeError(console, 'Invalid option: ${key.char}!');
    }
  }
}
