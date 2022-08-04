import 'dart:io';

import 'package:paxchange/src/util/directory_json_converter.dart';
import 'package:test/test.dart';

void main() {
  group('$DirectoryJsonConverter', () {
    test('fromJson create directory from path', () {
      const path = '/tmp/path';

      final result = const DirectoryJsonConverter().fromJson(path);

      expect(result.path, path);
    });

    test('toJson returns path of directory', () {
      final directory = Directory('/tmp/path');

      final result = const DirectoryJsonConverter().toJson(directory);

      expect(result, directory.path);
    });
  });
}
