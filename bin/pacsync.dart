import 'dart:io';

import 'package:args/args.dart';
import 'package:pacsync/src/config.dart';
import 'package:pacsync/src/package_sync.dart';
import 'package:riverpod/riverpod.dart';

const _storageDirectoryOption = 'storage-directory';
const _machineNameOption = 'machine-name';
const _setExitOnChangedFlag = 'set-exit-on-changed';

Future<void> main(List<String> rawArguments) async {
  final arguments = await _parse(rawArguments);

  final storageDirectory = Directory(
    arguments[_storageDirectoryOption] as String,
  );
  final machineName = arguments[_machineNameOption] as String;
  final setExitOnChanges = arguments[_setExitOnChangedFlag] as bool;

  final di = ProviderContainer(
    overrides: [
      configProvider.overrideWithValue(
        Config(
          storageDirectory: storageDirectory,
        ),
      ),
    ],
  );

  try {
    final packageSync = di.read(packageSyncProvider);
    final changeCount = await packageSync.updatePackageDiff(machineName);

    if (changeCount > 0) {
      stdout
        ..writeln('>>> $changeCount package(s) have changed!')
        ..writeln('>>> Please review the package changelog.');

      if (setExitOnChanges) {
        exitCode = 2;
      }
    }
  } on Exception catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  } finally {
    di.dispose();
  }
}

Future<ArgResults> _parse(List<String> arguments) async {
  const helpFlag = 'help';

  final argParser = ArgParser()
    ..addOption(
      _storageDirectoryOption,
      abbr: 'd',
      defaultsTo: '/etc/pacsync',
      valueHelp: 'path',
      help: 'Path to the directory where the package history should be stored.',
    )
    ..addOption(
      _machineNameOption,
      abbr: 'n',
      defaultsTo: Platform.localHostname,
      valueHelp: 'name',
      help: 'The name of the current machine. Defaults to the hostname.',
    )
    ..addFlag(
      _setExitOnChangedFlag,
      abbr: 'e',
      help: 'Causes the tool to exit with code 2 if packages have changed.',
    )
    ..addFlag(
      helpFlag,
      abbr: 'h',
      negatable: false,
    );

  try {
    final argResults = argParser.parse(arguments);

    if (argResults[helpFlag] as bool) {
      stdout.writeln(argParser.usage);
      await stdout.flush();
      exit(0);
    }

    return argResults;
  } on FormatException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln()
      ..writeln(argParser.usage);
    await stderr.flush();
    exit(127);
  }
}
