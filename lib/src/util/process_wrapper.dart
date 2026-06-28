// coverage:ignore-file

import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'process_wrapper.g.dart';

// coverage:ignore-start
@riverpod
ProcessWrapper process(Ref ref) => const ProcessWrapper();
// coverage:ignore-end

class ProcessWrapper {
  const ProcessWrapper();

  Future<Process> start(
    String executable,
    List<String> arguments, {
    ProcessStartMode mode = ProcessStartMode.normal,
    Map<String, String>? environment,
  }) => Process.start(
    executable,
    arguments,
    mode: mode,
    environment: environment,
  );
}
