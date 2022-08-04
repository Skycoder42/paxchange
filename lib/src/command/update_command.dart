import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../package_sync.dart';

class UpdateCommand extends Command<int> {
  @visibleForTesting
  static const setExitOnChangedFlag = 'set-exit-on-changed';

  final ProviderContainer _providerContainer;

  @override
  String get name => 'update';

  @override
  String get description =>
      'Update the package diff with the current system package configuration.';

  @override
  bool get takesArguments => false;

  UpdateCommand(this._providerContainer) {
    argParser.addFlag(
      setExitOnChangedFlag,
      abbr: 'e',
      help: 'Causes the tool to exit with code 2 if packages have changed.',
    );
  }

  @override
  Future<int> run() async {
    final setExitOnChanges = argResults![setExitOnChangedFlag] as bool;
    final packageSync = _providerContainer.read(packageSyncProvider);

    final changeCount = await packageSync.updatePackageDiff();

    if (changeCount > 0) {
      stdout
        ..writeln('>>> $changeCount package(s) have changed!')
        ..writeln('>>> Please review the package changelog.');

      if (setExitOnChanges) {
        return 2;
      }
    }

    return 0;
  }
}
