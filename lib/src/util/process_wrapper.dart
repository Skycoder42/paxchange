// coverage:ignore-file

import 'dart:io';

import 'package:riverpod/riverpod.dart';

final processProvider = Provider(
  (ref) => const ProcessWrapper(),
);

class ProcessWrapper {
  const ProcessWrapper();

  Future<Process> start(String executable, List<String> arguments) =>
      Process.start(executable, arguments);
}
