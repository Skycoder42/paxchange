import 'package:dart_console/dart_console.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../package_sync.dart';
import '../providers/console_provider.dart';
import '../storage/package_file_adapter.dart';
import '../storage/package_file_hierarchy.dart';
import 'command_editor.dart';
import 'commands/prompt_command.dart';
import 'commands/quit_command.dart';
import 'commands/skip_command.dart';
import 'prompter.dart';

part 'editor.g.dart';

// coverage:ignore-start
@riverpod
Editor editor(Ref ref, List<dynamic> editors) => Editor(
  ref.watch(consoleProvider),
  ref.watch(prompterProvider),
  ref.watch(packageFileAdapterProvider),
  ref.watch(packageSyncProvider),
  editors.cast<CommandEditor<dynamic>>(),
);
// coverage:ignore-end

enum EditorResult { quit, next, reload }

class Editor {
  final Console _console;
  final Prompter _prompter;
  final PackageFileAdapter _packageFileAdapter;
  final PackageSync _packageSync;
  final List<CommandEditor<dynamic>> _editors;

  final _skipped = <String>{};
  var _didModify = false;

  Editor(
    this._console,
    this._prompter,
    this._packageFileAdapter,
    this._packageSync,
    this._editors,
  );

  Future<void> run(String machineName) async {
    if (!_console.hasTerminal) {
      throw Exception('Cannot run without an interactive ANSI terminal!');
    }

    await _packageFileAdapter.ensurePackageFileExists(machineName);

    _skipped.clear();
    var reload = false;
    do {
      _didModify = false;

      final packageFileHierarchy = await _packageFileAdapter
          .loadPackageFileHierarchy(machineName);

      for (final editor in _editors) {
        final result = await _runEditor(
          packageFileHierarchy: packageFileHierarchy,
          editor: editor,
          machineName: machineName,
        );

        switch (result) {
          case EditorResult.quit:
            reload = false;
          case EditorResult.next:
            continue;
          case EditorResult.reload:
            reload = true;
        }
        break;
      }

      if (_didModify) {
        await _updatePackageDiff(skipResultMessage: reload);
      } else {
        _console.writeLine('No packages modified, nothing to do!');
      }
    } while (reload);
  }

  Future<EditorResult> _runEditor({
    required PackageFileHierarchy packageFileHierarchy,
    required CommandEditor<dynamic> editor,
    required String machineName,
  }) async {
    final targets = editor.loadTargets(machineName, packageFileHierarchy);
    await for (final target in targets) {
      final package = editor.packageForTarget(target);
      if (_skipped.contains(package)) {
        continue;
      }

      final entryResult = await _prompter.promptCommand(
        packageName: package,
        commands: [
          await for (final command in editor.buildCommands(
            machineName,
            packageFileHierarchy,
            target,
          ))
            command,
          SkipCommand(_console),
          QuitCommand(_console),
        ],
      );

      if (entryResult.didModify) {
        _didModify = true;
        _console
          ..writeLine('Press any key to continue...')
          ..readKey();
      }

      switch (entryResult) {
        case PromptResult.skipped:
          _skipped.add(package);
        case PromptResult.succeededReload:
          return EditorResult.reload;
        case PromptResult(stopProcessing: true):
          return EditorResult.quit;
        case _:
          break;
      }
    }

    return EditorResult.next;
  }

  Future<void> _updatePackageDiff({bool skipResultMessage = false}) async {
    _console
      ..clearScreen()
      ..writeLine('Updating package changelog, please wait...');

    final result = await _packageSync.updatePackageDiff();

    if (!skipResultMessage) {
      _console
        ..writeLine('Successfully regenerated package changelog!')
        ..writeLine('It now contains $result entries');
    }
  }
}
