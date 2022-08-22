import 'package:args/command_runner.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../config.dart';
import '../package_install.dart';

class InstallCommand extends Command<int> {
  @visibleForTesting
  static const machineNameOption = 'machine-name';
  @visibleForTesting
  static const confirmFlag = 'confirm';

  final ProviderContainer _providerContainer;

  @override
  String get name => 'install';

  @override
  String get description => '''
Triggers installation of all packages for this machine.

This will start the install command with all packages listed in the package file
of this machine, by only packages that are not already installed will be
installed. If you need fine control over which packages to install, run the
review command instead.''';

  @override
  bool get takesArguments => false;

  InstallCommand(this._providerContainer) {
    argParser
      ..addOption(
        machineNameOption,
        abbr: 'n',
        aliases: const ['name', 'machine'],
        valueHelp: 'name',
        help: 'Specify a custom machine name to install packages for. '
            'By default, this machine is used.',
      )
      ..addFlag(
        confirmFlag,
        defaultsTo: true,
        help: 'When disabled, the pacman installation will run '
            'without confirmation. Use carefully!',
      );
  }

  @override
  Future<int> run() {
    final machineName = argResults![machineNameOption] as String?;
    final confirm = argResults![confirmFlag] as bool;
    final config = _providerContainer.read(configProvider);

    final packageInstall = _providerContainer.read(packageInstallProvider);

    return packageInstall.installPackages(
      machineName ?? config.rootPackageFile,
      noConfirm: !confirm,
    );
  }
}
