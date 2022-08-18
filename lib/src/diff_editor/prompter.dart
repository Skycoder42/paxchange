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

  void writeTitle({
    required Console console,
    required String messagePrefix,
    required String package,
    required String messageSuffix,
    required ConsoleColor color,
  }) {
    console
      ..resetColorAttributes()
      ..clearScreen()
      ..setForegroundColor(color)
      ..write(messagePrefix)
      ..setTextStyle(bold: true)
      ..write(package)
      ..setTextStyle()
      ..setForegroundColor(color)
      ..writeLine(messageSuffix)
      ..resetColorAttributes();
  }

  FutureOr<PromptResult> prompt({
    required Console console,
    required String packageName,
    required List<PromptCommand> commands,
  }) async {
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

      var repeat = false;
      for (final command in commands) {
        if (command.key == key.char) {
          final result = await command(console, packageName);
          if (result == PromptResult.repeat) {
            repeat = true;
            break;
          }
          return result;
        }
      }

      if (!repeat) {
        writeError(console, 'Invalid option: ${key.char}!');
      }
    }
  }
}
