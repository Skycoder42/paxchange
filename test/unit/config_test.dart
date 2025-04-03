import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:paxchange/src/config.dart';
import 'package:test/test.dart';

void main() {
  group('$Config', () {
    testData<(String?, String)>(
      'rootPackageFile reports correct value',
      [(null, Platform.localHostname), const ('test-host', 'test-host')],
      (fixture) {
        final config = Config(
          storageDirectory: Directory.current,
          machineName: fixture.$1,
        );

        expect(config.rootPackageFile, fixture.$2);
      },
    );

    testData<(Config, Map<String, dynamic>)>(
      'serialization',
      [
        (
          Config(storageDirectory: Directory.current),
          <String, dynamic>{
            'storageDirectory': Directory.current.path,
            'machineName': null,
            'pacmanFrontend': null,
          },
        ),
        (
          Config(
            storageDirectory: Directory.systemTemp,
            machineName: 'test-machine',
            pacmanFrontend: 'yay',
          ),
          <String, dynamic>{
            'storageDirectory': Directory.systemTemp.path,
            'machineName': 'test-machine',
            'pacmanFrontend': 'yay',
          },
        ),
      ],
      (fixture) {
        expect(fixture.$1.toJson(), fixture.$2);
        expect(Config.fromJson(fixture.$2), _configEquals(fixture.$1));
      },
    );
  });
}

Matcher _configEquals(Config config) => isA<Config>()
    .having(
      (c) => c.storageDirectory.path,
      'storageDirectory',
      config.storageDirectory.path,
    )
    .having((c) => c.machineName, 'machineName', config.machineName)
    .having((c) => c.pacmanFrontend, 'pacmanFrontend', config.pacmanFrontend);
