import 'package:dart_console/dart_console.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../storage/package_file_adapter.dart';
import 'prompt_command.dart';

abstract class UpdateHistoryCommand extends PromptCommand {
  @protected
  final PackageFileAdapter packageFileAdapter;

  const UpdateHistoryCommand(this.packageFileAdapter);

  @override
  Future<PromptResult> call(Console console, String packageName) async {
    console
      ..writeLine()
      ..writeLine('$operation $packageName for $machineName...');
    await updateHistory(packageName);
    console
      ..writeLine('Success! Press any key to continue...')
      ..readKey();

    return PromptResult.succeeded;
  }

  @protected
  String get operation;

  @protected
  String get machineName;

  @protected
  Future<void> updateHistory(String packageName);
}

class AddHistoryCommand extends UpdateHistoryCommand {
  final int index;
  @override
  final String machineName;

  const AddHistoryCommand(
    super.packageFileAdapter,
    this.index,
    this.machineName,
  );

  static List<AddHistoryCommand> generate(
    PackageFileAdapter packageFileAdapter,
    List<String> machineHierarchy,
  ) =>
      List.generate(
        machineHierarchy.length,
        (index) => AddHistoryCommand(
          packageFileAdapter,
          index,
          machineHierarchy[index],
        ),
      );

  @override
  String get key => index.toString();

  @override
  String get description => 'Add package to $machineName';

  @override
  String get operation => 'Adding';

  @override
  Future<void> updateHistory(String packageName) =>
      packageFileAdapter.addToPackageFile(machineName, packageName);
}

class RemoveHistoryCommand extends UpdateHistoryCommand {
  @override
  final String machineName;

  const RemoveHistoryCommand(
    super.packageFileAdapter,
    this.machineName,
  );

  @override
  String get key => 'd';

  @override
  String get description => 'Delete the package from the package history';

  @override
  String get operation => 'Removing';

  @override
  Future<void> updateHistory(String packageName) =>
      packageFileAdapter.removeFromPackageFile(machineName, packageName);
}
