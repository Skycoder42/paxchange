import 'package:dart_console/dart_console.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/console_provider.dart';
import 'commands/prompt_command.dart';

part 'prompter.g.dart';

// coverage:ignore-start
@riverpod
Prompter prompter(Ref ref) => Prompter(ref.watch(consoleProvider));
// coverage:ignore-end

class Prompter {
  final Console _console;

  const Prompter(this._console);

  void writeError(String message) {
    _console
      ..setForegroundColor(ConsoleColor.red)
      ..writeLine()
      ..writeLine(message)
      ..resetColorAttributes();
  }

  void writeTitle({
    required String messagePrefix,
    required String messageHighlight,
    required String messageSuffix,
    required ConsoleColor color,
  }) {
    _console
      ..resetColorAttributes()
      ..clearScreen()
      ..setForegroundColor(color)
      ..write(messagePrefix)
      ..setTextStyle(bold: true)
      ..write(messageHighlight)
      ..setTextStyle()
      ..setForegroundColor(color)
      ..writeLine(messageSuffix)
      ..resetColorAttributes();
  }

  String promptOption({
    required String description,
    required Map<String, String> options,
  }) {
    while (true) {
      _console.writeLine(description);
      for (final MapEntry(:key, :value) in options.entries) {
        _console
          ..write('  ')
          ..setForegroundColor(ConsoleColor.blue)
          ..write(key)
          ..resetColorAttributes()
          ..write(': $value\n');
      }

      _console
        ..write('> ')
        ..setTextStyle(blink: true);
      final key = _console.readKey();
      _console.setTextStyle();

      if (options.containsKey(key.char)) {
        _console
          ..setForegroundColor(ConsoleColor.green)
          ..write(key.char)
          ..resetColorAttributes()
          ..writeLine();
        return key.char;
      } else {
        writeError('Invalid option: ${key.char}!');
      }
    }
  }

  FutureOr<PromptResult> promptCommand({
    required String packageName,
    required List<PromptCommand> commands,
  }) async {
    while (true) {
      final selectedKey = promptOption(
        description: 'What do you want to do?',
        options: {
          for (final command in commands) command.key: command.description,
        },
      );

      final selectedCommand = commands.singleWhere((c) => c.key == selectedKey);
      final result = await selectedCommand(packageName);
      if (result != PromptResult.repeat) {
        return result;
      }
    }
  }
}
