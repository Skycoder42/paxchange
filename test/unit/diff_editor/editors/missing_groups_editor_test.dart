import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/update_history_command.dart';
import 'package:paxchange/src/diff_editor/editors/missing_groups_editor.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:paxchange/src/storage/package_file_hierarchy.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

class MockPrompter extends Mock implements Prompter {}

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

void main() {
  group('$MissingGroupsEditor', () {
    const testMachineName = 'test-machine';
    const testGroup = 'test-missing-group';
    const testMissingGroups = {testGroup, 'group-2', 'group-3'};
    const testHierarchy = PackageFileHierarchy(
      packageFiles: {},
      groupsByPackages: {},
      missingGroups: testMissingGroups,
    );

    final mockConsole = MockConsole();
    final mockPrompter = MockPrompter();
    final mockPackageFileAdapter = MockPackageFileAdapter();

    late MissingGroupsEditor sut;

    setUp(() {
      reset(mockConsole);
      reset(mockPrompter);
      reset(mockPackageFileAdapter);

      sut = MissingGroupsEditor(
        mockConsole,
        mockPrompter,
        mockPackageFileAdapter,
      );
    });

    test('loadTargets returns missing groups from hierarchy', () {
      final result = sut.loadTargets(testMachineName, testHierarchy);

      expect(result, emitsInOrder([...testMissingGroups, emitsDone]));
    });

    test('buildCommands writes title and returns remove command', () async {
      final result = sut.buildCommands(
        testMachineName,
        testHierarchy,
        testGroup,
      );

      await expectLater(
        result,
        emitsInOrder([
          isA<RemoveHistoryCommand>()
              .having((m) => m.packageName, 'packageName', testGroup)
              .having((m) => m.machineName, 'machineName', testMachineName)
              .having((m) => m.isGroup, 'isGroup', isTrue),
          emitsDone,
        ]),
      );

      verify(
        () => mockPrompter.writeTitle(
          message: 'Found non existing group **$testGroup** in the history!',
          color: ConsoleColor.magenta,
        ),
      ).called(1);
    });
  });
}
