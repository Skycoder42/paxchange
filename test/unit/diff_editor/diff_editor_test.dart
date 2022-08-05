import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/diff_editor/diff_editor.dart';
import 'package:paxchange/src/diff_editor/prompter.dart';
import 'package:paxchange/src/package_sync.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/storage/diff_file_adapter.dart';
import 'package:paxchange/src/storage/package_file_adapter.dart';
import 'package:test/test.dart';

class MockPackageFileAdapter extends Mock implements PackageFileAdapter {}

class MockDiffFileAdapter extends Mock implements DiffFileAdapter {}

class MockPacman extends Mock implements Pacman {}

class MockPackageSync extends Mock implements PackageSync {}

class MockPrompter extends Mock implements Prompter {}

class MockStdout extends Mock implements Stdout {}

class MockConsole extends Mock implements Console {}

void main() {
  group('$DiffEditor', () {
    const testMachineName = 'test-machine';

    final mockPackageFileAdapter = MockPackageFileAdapter();
    final mockDiffFileAdapter = MockDiffFileAdapter();
    final mockPacman = MockPacman();
    final mockPackageSync = MockPackageSync();
    final mockStdout = MockStdout();
    final mockPrompter = MockPrompter();

    late DiffEditor sut;

    setUp(() {
      reset(mockPackageFileAdapter);
      reset(mockDiffFileAdapter);
      reset(mockPacman);
      reset(mockPackageSync);
      reset(mockStdout);
      reset(mockPrompter);

      sut = DiffEditor(
        mockPackageFileAdapter,
        mockDiffFileAdapter,
        mockPacman,
        mockPackageSync,
        mockPrompter,
      );
    });

    group(
      'run',
      () => IOOverrides.runZoned(stdout: () => mockStdout, () {
        test('throws exception if console does not have a terminal', () {
          when(() => mockStdout.hasTerminal).thenReturn(false);

          expect(() => sut.run(testMachineName), throwsA(isException));
        });

        test(
          'throws exception if stdout does not support ansi',
          () {
            when(() => mockStdout.hasTerminal).thenReturn(true);
            when(() => mockStdout.supportsAnsiEscapes).thenReturn(false);

            expect(() => sut.run(testMachineName), throwsA(isException));
          },
        );

        test('presents added diff entry', () {
          fail('TODO');
        });
      }),
    );
  });
}
