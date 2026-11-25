import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../storage/package_file_adapter.dart';
import '../prompter.dart';
import 'prompt_command.dart';

abstract base class const UpdateHistoryCommand(
  Console console,
  @protected final PackageFileAdapter packageFileAdapter,
  final Prompter _prompter, {
  required String packageName,
}) extends PromptCommand {
  this : super(console, packageName);

  @override
  Future<PromptResult> call() async {
    console.writeLine('$operation $packageName for $machineName...');
    final success = await updateHistory(packageName);
    if (success) {
      return PromptResult.succeeded;
    } else {
      _prompter.writeError('$operation $packageName for $machineName failed!');
      return PromptResult.failed;
    }
  }

  @protected
  String get operation;

  @protected
  String get machineName;

  @protected
  Future<bool> updateHistory(String packageName);
}

final class const AddHistoryCommand(
  super.console,
  super.packageFileAdapter,
  super._prompter,
  final int index, {
  @override required final String machineName,
  required super.packageName,
}) extends UpdateHistoryCommand {
  static List<AddHistoryCommand> generate(
    Console console,
    PackageFileAdapter packageFileAdapter,
    Prompter prompter,
    Iterable<String> machineHierarchy,
    String packageName,
  ) => [
    for (final (index, packageFileName)
        in machineHierarchy.toList().reversed.indexed)
      AddHistoryCommand(
        console,
        packageFileAdapter,
        prompter,
        index + 1,
        machineName: packageFileName,
        packageName: packageName,
      ),
  ];

  @override
  String get key => index.toString();

  @override
  String get description => 'Add package to $machineName';

  @override
  String get operation => 'Adding';

  @override
  Future<bool> updateHistory(String packageName) async {
    await super.packageFileAdapter.addToPackageFile(machineName, packageName);
    return true;
  }
}

final class const RemoveHistoryCommand(
  super.console,
  super.packageFileAdapter,
  super._prompter, {
  @override required final String machineName,
  required super.packageName,
  final bool isGroup = false,
}) extends UpdateHistoryCommand {
  @override
  String get key => 'd';

  @override
  String get description => 'Delete the package from the package history';

  @override
  String get operation => 'Removing';

  @override
  Future<bool> updateHistory(String packageName) => super.packageFileAdapter
      .removeFromPackageFile(machineName, packageName, isGroup: isGroup);
}
