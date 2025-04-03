import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../package_sync.dart';

part 'update_command.g.dart';

@immutable
@CliOptions(createCommand: true)
final class UpdateOptions {
  @CliOption(
    abbr: 'e',
    help: 'Causes the tool to exit with code 2 if packages have changed.',
  )
  final bool setExitOnChanged;

  const UpdateOptions({required this.setExitOnChanged});
}

class UpdateCommand extends _$UpdateOptionsCommand<int> {
  final ProviderContainer _providerContainer;

  @override
  String get name => 'update';

  @override
  String get description =>
      'Update the package diff with the current system package configuration.';

  @override
  bool get takesArguments => false;

  UpdateCommand(this._providerContainer);

  @override
  Future<int> run() async {
    final packageSync = _providerContainer.read(packageSyncProvider);

    final changeCount = await packageSync.updatePackageDiff();

    if (changeCount > 0) {
      stdout
        ..writeln('>>> $changeCount package(s) have changed!')
        ..writeln('>>> Please review the package changelog.');

      if (_options.setExitOnChanged) {
        return 2;
      }
    }

    return 0;
  }
}
