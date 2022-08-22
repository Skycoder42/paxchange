// coverage:ignore-file

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:riverpod/riverpod.dart';

import '../config.dart';
import 'install_command.dart';
import 'review_command.dart';
import 'update_command.dart';

class PaxchangeRunner extends CommandRunner<int> {
  static const _configOption = 'config';

  late final ProviderContainer _providerContainer;

  PaxchangeRunner()
      : super(
          'paxchange',
          'Simple dart script to passively synchronize '
              'installed pacman packages between systems.',
        ) {
    _providerContainer = ProviderContainer(
      overrides: [
        configProvider.overrideWithProvider(configProvider),
      ],
    );

    argParser.addOption(
      _configOption,
      abbr: 'c',
      aliases: const ['config-file'],
      defaultsTo: '/etc/paxchange.json',
      valueHelp: 'path',
      help: 'Path to the configuration file to be used.',
    );

    addCommand(UpdateCommand(_providerContainer));
    addCommand(ReviewCommand(_providerContainer));
    addCommand(InstallCommand(_providerContainer));
  }

  void dispose() => _providerContainer.dispose();

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    final config = await _readConfig(topLevelResults[_configOption] as String);
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

    return configFile
        .openRead()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .cast<Map<String, dynamic>>()
        .map(Config.fromJson)
        .single;
  }
}
