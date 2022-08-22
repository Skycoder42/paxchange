import 'dart:convert';
import 'dart:io';

import 'package:paxchange/src/config.dart';
import 'package:test/test.dart';

void main() {
  group('paxchange install', () {
    late Directory testDir;
    late Directory packageDir;

    File _packageFile(String fileName) =>
        File.fromUri(packageDir.uri.resolve(fileName));

    Future<void> _writePackages(String fileName, Iterable<String> lines) =>
        _packageFile(fileName).writeAsString(lines.join('\n'));

    Future<bool> _checkInstalled(String package) async {
      final result = await Process.run('pacman', ['-Qi', package]);
      return result.exitCode == 0;
    }

    Future<int> _runPaxchange(String machineName) async {
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
        ],
      );
      proc.stdout.listen(stdout.add);
      proc.stderr.listen(stderr.add);
      proc.stdin.writeln('y');
      await proc.stdin.flush();
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
      expect(await _checkInstalled('bash'), isTrue);
      expect(await _checkInstalled('p7zip'), isFalse);

      const machineName = 'testMachine';
      await _writePackages(machineName, const ['bash', 'p7zip']);

      await _runPaxchange(machineName);

      expect(await _checkInstalled('bash'), isTrue);
      expect(await _checkInstalled('p7zip'), isTrue);
    });
  });
}
