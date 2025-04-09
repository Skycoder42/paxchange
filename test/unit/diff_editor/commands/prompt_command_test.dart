// ignore_for_file: unnecessary_lambdas

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockConsole());
  });

  group('$PromptResult', () {
    testData(
      'withReload maps to correct state',
      [
        (PromptResult.succeeded, PromptResult.succeededReload),
        (PromptResult.succeededReload, PromptResult.succeededReload),
        (PromptResult.failed, PromptResult.failed),
        (PromptResult.repeat, PromptResult.repeat),
        (PromptResult.skipped, PromptResult.skipped),
        (PromptResult.quit, PromptResult.quit),
      ],
      (fixture) {
        expect(fixture.$1.withReload(), fixture.$2);
      },
    );
  });
}
