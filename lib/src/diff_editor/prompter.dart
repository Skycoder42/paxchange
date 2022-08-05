import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:riverpod/riverpod.dart';
import 'commands/prompt_command.dart';

// coverage:ignore-start
final prompterProvider = Provider(
  (ref) => const Prompter(),
);
// coverage:ignore-end

class Prompter {
  static void writeError(Console console, String message) {
    console
      ..setForegroundColor(ConsoleColor.red)
      ..writeLine()
      ..writeLine(message)
      ..resetColorAttributes();
  }

  const Prompter();

  FutureOr<bool> prompt(
    Console console,
    String packageName,
    List<PromptCommand> commands,
  ) async {
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
