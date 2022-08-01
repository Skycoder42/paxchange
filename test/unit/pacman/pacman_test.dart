import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paxchange/src/pacman/pacman.dart';
import 'package:paxchange/src/util/process_wrapper.dart';
import 'package:test/test.dart';

class ProcessWrapperMock extends Mock implements ProcessWrapper {}

class ProcessMock extends Mock implements Process {}

class MockStderr extends Mock implements Stdout {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Stream<List<int>>.empty());
    registerFallbackValue(ProcessStartMode.normal);
  });

  group('$Pacman', () {
    final processWrapperMock = ProcessWrapperMock();
    final processMock = ProcessMock();
    final mockStderr = MockStderr();

    setUp(() {
      reset(processWrapperMock);
      reset(processMock);
      reset(mockStderr);

      when(
        () => processWrapperMock.start(
          any(),
          any(),
          mode: any(named: 'mode'),
        ),
      ).thenReturnAsync(processMock);
      when(() => processMock.stderr).thenStream(const Stream.empty());
      when(() => processMock.stdout).thenStream(const Stream.empty());
      when(() => processMock.exitCode).thenReturnAsync(0);
    });

    @isTestGroup
    void _testLineStreaming({
      required Stream<String> Function() runPacman,
    }) {
      test('returns lines of pacman command', () {
        const lines = ['line1', 'line2', 'line3'];
        when(() => processMock.stdout)
            .thenStream(Stream.value(lines.join('\n')).transform(utf8.encoder));

        expect(
          runPacman(),
          emitsInOrder(<dynamic>[
            ...lines,
            emitsDone,
          ]),
        );
      });

      test('emits error if pacman command fails', () {
        const firstLine = 'line';
        when(() => processMock.stdout)
            .thenStream(Stream.value(firstLine).transform(utf8.encoder));
        when(() => processMock.exitCode).thenReturnAsync(1);

        expect(
          runPacman(),
          emitsInOrder(<dynamic>[
            firstLine,
            emitsError(isException),
            emitsDone,
          ]),
        );
      });

      test(
        'forwards errors to stderr',
        () => IOOverrides.runZoned(
          stderr: () => mockStderr,
          () async {
            final errorStream = Stream.value([1, 2, 3]);
            when(() => processMock.stderr).thenStream(errorStream);
            when(() => mockStderr.addStream(any())).thenReturnAsync(null);

            await expectLater(runPacman(), emitsDone);

            verify(() => mockStderr.addStream(errorStream));
          },
        ),
      );

      test(
        'waits for stderr and forwards uncaught errors to zone handler',
        () => runZonedGuarded(
          () {
            final error = Exception('error');
            when(() => processMock.stderr).thenStream(const Stream.empty());
            when(() => mockStderr.addStream(any())).thenThrow(error);

            expect(runPacman(), emitsDone);

            verify(() => mockStderr.addError(error, any(that: isNotNull)));
          },
          mockStderr.addError,
        ),
      );
    }

    @isTestGroup
    void _testWithFrontend(String? frontend, String process) =>
        group('(frontend: $frontend)', () {
          late Pacman sut;

          setUp(() {
            sut = Pacman(processWrapperMock, frontend);
          });

          group('listExplicitlyInstalledPackages', () {
            test('invokes pacman to list packages', () async {
              final result = sut.listExplicitlyInstalledPackages();
              await expectLater(result, emitsDone);

              verify(() => processWrapperMock.start(process, const ['-Qqe']));
              verifyNoMoreInteractions(processWrapperMock);
            });

            _testLineStreaming(
              runPacman: () => sut.listExplicitlyInstalledPackages(),
            );
          });

          group('queryInstalledPackage', () {
            const testPackageName = 'test-package';

            test('invokes pacman to list packages details', () async {
              final result = sut.queryInstalledPackage(testPackageName);
              await expectLater(result, emitsDone);

              verify(
                () => processWrapperMock.start(
                  process,
                  const ['-Qi', testPackageName],
                ),
              );
              verifyNoMoreInteractions(processWrapperMock);
            });

            _testLineStreaming(
              runPacman: () => sut.queryInstalledPackage(testPackageName),
            );
          });

          group('queryUninstalledPackage', () {
            const testPackageName = 'test-package';

            test('invokes pacman to list packages details', () async {
              final result = sut.queryUninstalledPackage(testPackageName);
              await expectLater(result, emitsDone);

              verify(
                () => processWrapperMock.start(
                  process,
                  const ['-Si', testPackageName],
                ),
              );
              verifyNoMoreInteractions(processWrapperMock);
            });

            _testLineStreaming(
              runPacman: () => sut.queryUninstalledPackage(testPackageName),
            );
          });

          test('installPackage starts pacman in interactive install mode',
              () async {
            const testPackageName = 'test-package';
            const exitCode = 42;

            when(() => processMock.exitCode).thenReturnAsync(exitCode);

            final result = await sut.installPackage(testPackageName);

            verify(
              () => processWrapperMock.start(
                process,
                const ['-S', testPackageName],
                mode: ProcessStartMode.inheritStdio,
              ),
            );
            verifyNever(() => processMock.stdout);
            verifyNever(() => processMock.stderr);
            expect(result, exitCode);
          });

          test('removePackage starts pacman in interactive remove mode',
              () async {
            const testPackageName = 'test-package';
            const exitCode = 42;

            when(() => processMock.exitCode).thenReturnAsync(exitCode);

            final result = await sut.removePackage(testPackageName);

            verify(
              () => processWrapperMock.start(
                process,
                const ['-R', testPackageName],
                mode: ProcessStartMode.inheritStdio,
              ),
            );
            verifyNever(() => processMock.stdout);
            verifyNever(() => processMock.stderr);
            expect(result, exitCode);
          });
        });

    _testWithFrontend(null, 'pacman');

    _testWithFrontend('yay', 'yay');
  });
}
