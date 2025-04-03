// coverage:ignore-file

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../config.dart';
import 'install_command.dart';
import 'review_command.dart';
import 'update_command.dart';

part 'paxchange_runner.g.dart';

@immutable
@CliOptions()
final class GlobalOptions {
  @CliOption(
    abbr: 'c',
    defaultsTo: '/etc/paxchange.json',
    valueHelp: 'path',
    help: 'Path to the configuration file to be used.',
  )
  final String config;

  const GlobalOptions({required this.config});
}

class PaxchangeRunner extends CommandRunner<int> {
  late final ProviderContainer _providerContainer;

  PaxchangeRunner()
    : super(
        'paxchange',
        'Simple dart script to passively synchronize '
            'installed pacman packages between systems.',
      ) {
    _providerContainer = ProviderContainer(
      overrides: [
        configProvider.overrideWith((ref) => ref.watch(configProvider)),
      ],
    );

    _$populateGlobalOptionsParser(argParser);
    addCommand(UpdateCommand(_providerContainer));
    addCommand(ReviewCommand(_providerContainer));
    addCommand(InstallCommand(_providerContainer));
  }

  void dispose() => _providerContainer.dispose();

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    final options = _$parseGlobalOptionsResult(topLevelResults);
    final config = await _readConfig(options.config);
    _providerContainer.updateOverrides([
      configProvider.overrideWithValue(config),
    ]);

    return super.runCommand(topLevelResults);
  }

  Future<Config> _readConfig(String path) async {
    final configFile = File(path);
    if (!configFile.existsSync()) {
      throw Exception('Configuration file $path does not exist!');
    }

    return await configFile
        .openRead()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .cast<Map<String, dynamic>>()
        .map(Config.fromJson)
        .single;
  }
}
