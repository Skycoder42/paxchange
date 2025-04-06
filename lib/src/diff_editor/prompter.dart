import 'package:dart_console/dart_console.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'commands/prompt_command.dart';

part 'prompter.g.dart';

// coverage:ignore-start
@riverpod
Prompter prompter(Ref ref) => const Prompter();
// coverage:ignore-end

class Prompter {
  const Prompter();

  void writeError(Console console, String message) {
    console
      ..setForegroundColor(ConsoleColor.red)
      ..writeLine()
      ..writeLine(message)
      ..resetColorAttributes();
  }

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

  String promptOption({
    required Console console,
    required String description,
    required Map<String, String> options,
  }) {
    while (true) {
      console.writeLine(description);
      for (final MapEntry(:key, :value) in options.entries) {
        console
          ..write('  ')
          ..setForegroundColor(ConsoleColor.blue)
          ..write(key)
          ..resetColorAttributes()
          ..write(': $value\n');
      }

      console
        ..write('> ')
        ..setTextStyle(blink: true);
      final key = console.readKey();
      console.setTextStyle();

      if (options.containsKey(key.char)) {
        return key.char;
      } else {
        writeError(console, 'Invalid option: ${key.char}!');
      }
    }
  }

  FutureOr<PromptResult> promptCommand({
    required Console console,
    required String packageName,
    required List<PromptCommand> commands,
  }) async {
    while (true) {
      final selectedKey = promptOption(
        console: console,
        description: 'What do you want to do?',
        options: {
          for (final command in commands) command.key: command.description,
        },
      );

      final selectedCommand = commands.singleWhere((c) => c.key == selectedKey);
      final result = await selectedCommand(console, packageName);
      if (result != PromptResult.repeat) {
        return result;
      }
    }
  }
}
