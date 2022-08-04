import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:paxchange/src/command/paxchange_runner.dart';

Future<void> main(List<String> arguments) async {
  final paxchangeRunner = PaxchangeRunner();
  try {
    final result = await paxchangeRunner.run(arguments);
    exitCode = result ?? 0;
  } on UsageException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln()
      ..writeln(e.usage);
    await stderr.flush();
    exitCode = 127;
  } on Exception catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  } finally {
    paxchangeRunner.dispose();
  }
}
