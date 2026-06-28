// coverage:ignore-file

import 'package:dart_console/dart_console.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'console_provider.g.dart';

@riverpod
Console console(Ref ref) => Console.scrolling();
