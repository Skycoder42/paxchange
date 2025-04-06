import 'dart:async';
import 'dart:collection';

import 'package:dart_console/dart_console.dart';

class TestConsole implements Console {
  final outputController = StreamController<String?>();
  final inputController = StreamController<dynamic>();
  final _inputQueue = Queue<dynamic>();
  late final StreamSubscription<dynamic> _inputSub;

  TestConsole() {
    _inputSub = inputController.stream.listen(_inputQueue.add);
  }

  Future<void> close() async => await Future.wait([
    _inputSub.cancel(),
    inputController.close(),
    outputController.close(),
  ]);

  Stream<String?> get output => outputController.stream;

  Sink<dynamic> get input => inputController.sink;

  // writing

  @override
  void write(Object text) => outputController.add(text.toString());

  @override
  void writeLine([
    Object? text,
    TextAlignment alignment = TextAlignment.left,
  ]) =>
      outputController
        ..add(text?.toString() ?? '')
        ..add('\n');

  @override
  void clearScreen() => outputController.add(null);

  // reading

  @override
  Key readKey() => _inputQueue.removeFirst() as Key;

  // stubs

  @override
  bool get hasTerminal => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
