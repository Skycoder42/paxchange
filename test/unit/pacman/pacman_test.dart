import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_test_tools/test.dart';
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
  });

  group('$Pacman', () {
    final processWrapperMock = ProcessWrapperMock();
    final processMock = ProcessMock();
    final mockStderr = MockStderr();

    late Pacman sut;

    setUp(() {
      reset(processWrapperMock);
      reset(processMock);
      reset(mockStderr);

      when(() => processWrapperMock.start(any(), any()))
          .thenReturnAsync(processMock);
      when(() => processMock.stderr).thenStream(const Stream.empty());
      when(() => processMock.stdout).thenStream(const Stream.empty());
      when(() => processMock.exitCode).thenReturnAsync(0);

      sut = Pacman(processWrapperMock);
    });

    group('listExplicitlyInstalledPackages', () {
      test('invokes pacman to list packages', () async {
        final result = sut.listExplicitlyInstalledPackages();
        await expectLater(result, emitsDone);

        verify(() => processWrapperMock.start('pacman', const ['-Qqe']));
        verifyNoMoreInteractions(processWrapperMock);
      });

      test('returns lines of pacman command', () {
        const lines = ['line1', 'line2', 'line3'];
        when(() => processMock.stdout)
            .thenStream(Stream.value(lines.join('\n')).transform(utf8.encoder));

        final result = sut.listExplicitlyInstalledPackages();
        expect(
          result,
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

        final result = sut.listExplicitlyInstalledPackages();
        expect(
          result,
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

            final result = sut.listExplicitlyInstalledPackages();
            await expectLater(result, emitsDone);

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

            final result = sut.listExplicitlyInstalledPackages();
            expect(result, emitsDone);

            verify(() => mockStderr.addError(error, any(that: isNotNull)));
          },
          mockStderr.addError,
        ),
      );
    });
  });
}
