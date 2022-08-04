import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:paxchange/src/config.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('$Config', () {
    testData<Tuple2<String?, String>>(
      'rootPackageFile reports correct value',
      [
        Tuple2(null, Platform.localHostname),
        const Tuple2('test-host', 'test-host'),
      ],
      (fixture) {
        final config = Config(
          storageDirectory: Directory.current,
          machineName: fixture.item1,
        );

        expect(config.rootPackageFile, fixture.item2);
      },
    );

    testData<Tuple2<Config, Map<String, dynamic>>>(
      'serialization',
      [
        Tuple2(
          Config(storageDirectory: Directory.current),
          <String, dynamic>{
            'storageDirectory': Directory.current.path,
            'machineName': null,
            'pacmanFrontend': null,
          },
        ),
        Tuple2(
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
        expect(fixture.item1.toJson(), fixture.item2);
        expect(Config.fromJson(fixture.item2), _configEquals(fixture.item1));
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
