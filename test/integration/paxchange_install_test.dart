import 'dart:convert';
import 'dart:io';

import 'package:paxchange/src/config.dart';
import 'package:test/test.dart';

void main() {
  group('paxchange install', () {
    late Directory testDir;
    late Directory packageDir;

    File packageFile(String fileName) =>
        File.fromUri(packageDir.uri.resolve(fileName));

    Future<void> writePackages(String fileName, Iterable<String> lines) async =>
        packageFile(fileName).writeAsString(lines.join('\n'));

    Future<bool> checkInstalled(String package) async {
      final result = await Process.run('pacman', ['-Qi', package]);
      return result.exitCode == 0;
    }

    Future<int> runPaxchange(String machineName) async {
      final configFile = File.fromUri(testDir.uri.resolve('config.json'));
      await configFile.writeAsString(
        json.encode(
          Config(
            storageDirectory: packageDir,
            machineName: machineName,
          ),
        ),
      );

      final proc = await Process.start(
        'dart',
        [
          'run',
          'bin/paxchange.dart',
          '--config',
          configFile.path,
          'install',
          '--no-confirm',
        ],
        mode: ProcessStartMode.inheritStdio,
      );
      return proc.exitCode;
    }

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      packageDir = Directory.fromUri(testDir.uri.resolve('packages'));
      await packageDir.create();
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    test('installs needed packages', () async {
      expect(await checkInstalled('bash'), isTrue);
      expect(await checkInstalled('p7zip'), isFalse);

      const machineName = 'testMachine';
      await writePackages(machineName, const ['bash', 'p7zip']);

      await runPaxchange(machineName);

      expect(await checkInstalled('bash'), isTrue);
      expect(await checkInstalled('p7zip'), isTrue);
    });
  });
}
