import 'package:dart_console/dart_console.dart';
import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/commands/pacman_command.dart';
import 'package:paxchange/src/diff_editor/commands/print_command.dart';
import 'package:paxchange/src/diff_editor/editors/cleanup_editor.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/storage/package_file_hierarchy.dart';
import 'package:test/test.dart';

class MockConsole extends Mock implements Console {}

class MockPrompter extends Mock implements Prompter {}

class MockPacman extends Mock implements Pacman {}

void main() {
  group('$CleanupEditor', () {
    const testMachineName = 'test-machine';
    const testHierarchy = PackageFileHierarchy.empty;
    const testPackage = 'test-package';

    final mockConsole = MockConsole();
    final mockPrompter = MockPrompter();
    final mockPacman = MockPacman();

    late CleanupEditor sut;

    setUp(() {
      reset(mockConsole);
      reset(mockPrompter);
      reset(mockPacman);

      sut = CleanupEditor(
        mockConsole,
        mockPrompter,
        mockPacman,
        includeOptional: false,
      );
    });

    testData(
      'loadTargets loads queries pacman for unused packages',
      [false, true],
      (fixture) async {
        final testPackages = [testPackage, 'package-2'];

        when(
          () => mockPacman.listUnusedPackages(
            includeOptional: any(named: 'includeOptional'),
          ),
        ).thenStream(Stream.fromIterable(testPackages));

        sut = CleanupEditor(
          mockConsole,
          mockPrompter,
          mockPacman,
          includeOptional: fixture,
        );

        await expectLater(
          sut.loadTargets(testMachineName, testHierarchy),
          emitsInOrder([...testPackages, emitsDone]),
        );

        verify(
          () => mockPacman.listUnusedPackages(includeOptional: fixture),
        ).called(1);
      },
    );

    test('packageForTarget returns target', () {
      expect(sut.packageForTarget(testPackage), testPackage);
    });

    test('buildCommands writes title and creates expected commands', () async {
      final result = sut.buildCommands(
        testMachineName,
        testHierarchy,
        testPackage,
      );

      await expectLater(
        result,
        emitsInOrder([
          isA<PrintCommand>().having(
            (m) => m.printTarget,
            'printTarget',
            PrintTarget.local,
          ),
          isA<MarkExplicitlyInstalledCommand>(),
          isA<RemoveCommand>(),
          emitsDone,
        ]),
      );

      verify(
        () => mockPrompter.writeTitle(
          message:
              'Found implicitly installed package **$testPackage** that is '
              'not required by any other package!',
          color: ConsoleColor.yellow,
        ),
      ).called(1);
    });
  });
}
