// ignore_for_file: unnecessary_lambdas for tests

import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/add_group_command.dart';
import 'package:paxchange/src/diff_editor/commands/prompt_command.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockPacman extends Mock implements Pacman {}

class MockPrompter extends Mock implements Prompter {}

void main() {
  group('$AddGroupCommand', () {
    final testMachineHierarchy = ['machine1', 'machine2'];
    const testPackageName = 'test-package';
    const testGroup1 = 'group1';
    const testGroup2 = 'group2';
    final testPackageGroups = [testGroup1, testGroup2];
    final testGroupPackages = ['package-1', 'package-2'];

    final mockConsole = MockConsole();
    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockPacman = MockPacman();
    final mockPrompter = MockPrompter();

    late AddGroupCommand sut;

    setUp(() {
      reset(mockConsole);
      reset(mockPackageFileAdapter);
      reset(mockPacman);
      reset(mockPrompter);

      when(() => mockConsole.readKey()).thenReturn(Key.printable(' '));

      when(
        () => mockPacman.queryInstalledPackage(any()),
      ).thenStream(Stream.value('Groups: ${testPackageGroups.join(' ')}'));

      when(
        () => mockPacman.listPackagesForGroup(any()),
      ).thenStream(Stream.fromIterable(testGroupPackages));

      when(
        () => mockPackageFileAdapter.addToPackageFile(any(), any()),
      ).thenReturnAsync(null);
      when(
        () => mockPackageFileAdapter.removeFromPackageFile(
          any(),
          any(),
          recursive: any(named: 'recursive'),
        ),
      ).thenReturnAsync(true);

      when(
        () => mockPrompter.promptOption(
          description: any(named: 'description'),
          options: any(named: 'options'),
        ),
      ).thenReturn('0');

      sut = AddGroupCommand(
        mockConsole,
        mockPackageFileAdapter,
        mockPacman,
        mockPrompter,
        testMachineHierarchy,
        testPackageName,
      );
    });

    test('uses correct key', () {
      expect(sut.key, 'g');
    });

    group('call', () {
      test(
        'filters groups from package query and builds command from them',
        () async {
          when(() => mockPacman.queryInstalledPackage(any())).thenStream(
            Stream.fromIterable([
              'Package $testPackageName',
              'Group: ${testPackageGroups.first}',
              'Groups  :   ${testPackageGroups.join(' \t ')} ',
              'Other: g1 g2',
            ]),
          );
          when(
            () => mockPrompter.promptOption(
              description: any(named: 'description'),
              options: any(named: 'options'),
            ),
          ).thenReturn('c');

          await sut();

          verifyInOrder([
            () => mockPacman.queryInstalledPackage(testPackageName),
            () => mockPrompter.promptOption(
              description:
                  'Which group of $testPackageName do you want to add?',
              options: {
                for (final (index, group) in testPackageGroups.indexed)
                  '$index': group,
                'c': 'Cancel and return to main menu',
              },
            ),
          ]);
        },
      );

      test('returns empty list if package has no groups', () async {
        when(
          () => mockPacman.queryInstalledPackage(any()),
        ).thenStream(Stream.value('Groups : None'));

        final result = await sut();
        expect(result, PromptResult.repeat);

        verifyInOrder([
          () => mockPacman.queryInstalledPackage(testPackageName),
          () => mockConsole.writeLine('No groups found for $testPackageName'),
        ]);
        verifyNever(
          () => mockPrompter.promptOption(
            description: any(named: 'description'),
            options: any(named: 'options'),
          ),
        );
      });

      test('returns repeat if no group was selected', () async {
        when(
          () => mockPrompter.promptOption(
            description: any(named: 'description'),
            options: any(named: 'options'),
          ),
        ).thenReturn('c');

        final result = await sut();

        expect(result, PromptResult.repeat);

        verifyInOrder([
          () => mockPacman.queryInstalledPackage(testPackageName),
          () => mockPrompter.promptOption(
            description: any(named: 'description'),
            options: any(named: 'options'),
          ),
        ]);
      });

      test('builds prompt for group to select package history', () async {
        when(
          () => mockPrompter.promptOption(
            description: any(
              named: 'description',
              that: contains(testPackageName),
            ),
            options: any(named: 'options'),
          ),
        ).thenReturn('0');
        when(
          () => mockPrompter.promptOption(
            description: any(named: 'description', that: contains(testGroup1)),
            options: any(named: 'options'),
          ),
        ).thenReturn('c');

        await sut();

        verifyInOrder([
          () => mockPacman.queryInstalledPackage(testPackageName),
          () => mockPrompter.promptOption(
            description: any(named: 'description'),
            options: any(named: 'options'),
          ),
          () => mockPrompter.promptOption(
            description:
                'Which package history do you want to add $testGroup1 to?',
            options: {
              for (final (index, machine)
                  in testMachineHierarchy.reversed.indexed)
                '${index + 1}': 'Add package to $machine',
              'c': 'Cancel and return to main menu',
            },
          ),
        ]);
      });

      test('returns repeat if no add command was selected', () async {
        when(
          () => mockPrompter.promptOption(
            description: any(
              named: 'description',
              that: contains(testPackageName),
            ),
            options: any(named: 'options'),
          ),
        ).thenReturn('1');
        when(
          () => mockPrompter.promptOption(
            description: any(named: 'description', that: contains(testGroup2)),
            options: any(named: 'options'),
          ),
        ).thenReturn('c');

        final result = await sut();

        expect(result, PromptResult.repeat);

        verifyInOrder([
          () => mockPacman.queryInstalledPackage(testPackageName),
          () => mockPrompter.promptOption(
            description: any(named: 'description'),
            options: any(named: 'options'),
          ),
          () => mockPrompter.promptOption(
            description: any(named: 'description'),
            options: any(named: 'options'),
          ),
        ]);
      });

      test(
        'deletes packages for selected group from select history file',
        () async {
          when(
            () => mockPrompter.promptOption(
              description: any(named: 'description'),
              options: any(named: 'options'),
            ),
          ).thenReturn('1');

          await sut();

          verifyInOrder([
            () => mockPacman.queryInstalledPackage(testPackageName),
            () => mockPrompter.promptOption(
              description: any(named: 'description'),
              options: any(named: 'options'),
            ),
            () => mockPrompter.promptOption(
              description: any(named: 'description'),
              options: any(named: 'options'),
            ),
            () => mockPacman.listPackagesForGroup(testGroup2),
            for (final package in testGroupPackages)
              () => mockPackageFileAdapter.removeFromPackageFile(
                testMachineHierarchy.last,
                package,
                recursive: false,
              ),
          ]);
        },
      );

      test('adds selected group to select history file', () async {
        when(
          () => mockPrompter.promptOption(
            description: any(named: 'description'),
            options: any(named: 'options'),
          ),
        ).thenReturn('1');

        final result = await sut();

        expect(result, PromptResult.succeededReload);

        verifyInOrder([
          () => mockPacman.queryInstalledPackage(testPackageName),
          () => mockPrompter.promptOption(
            description: any(named: 'description'),
            options: any(named: 'options'),
          ),
          () => mockPrompter.promptOption(
            description: any(named: 'description'),
            options: any(named: 'options'),
          ),
          () => mockPacman.listPackagesForGroup(testGroup2),
          for (final package in testGroupPackages)
            () => mockPackageFileAdapter.removeFromPackageFile(
              testMachineHierarchy.last,
              package,
              recursive: false,
            ),
          () => mockPackageFileAdapter.addToPackageFile(
            testMachineHierarchy.last,
            '::group $testGroup2',
          ),
        ]);
      });
    });
  });
}
