import 'dart:convert';
import 'dart:io';

import 'package:paxchange/src/command/paxchange_runner.dart';
import 'package:paxchange/src/config.dart';
import 'package:paxchange/src/diff_editor/diff_editor.dart';
import 'package:test/test.dart';

import 'util/test_console.dart';

void main() {
  group('paxchange review', () {
    late Directory testDir;
    late Directory packageDir;

    Future<(Stream<String?>, Sink<dynamic>)> runPaxchange(
      String machineName,
    ) async {
      final configFile = File.fromUri(testDir.uri.resolve('config.json'));
      await configFile.writeAsString(
        json.encode(
          Config(storageDirectory: packageDir, machineName: machineName),
        ),
      );

      final console = TestConsole();
      final runner = PaxchangeRunner(
        extraOverrides: [consoleProvider.overrideWithValue(console)],
      );
      addTearDown(runner.dispose);

      expect(
        runner.run(['--config', configFile.path, 'review']),
        completion(0),
      );
      return (console.output, console.input);
    }

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      packageDir = Directory.fromUri(testDir.uri.resolve('packages'));
      await packageDir.create();
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });
  });
}
