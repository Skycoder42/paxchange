import 'dart:convert';
import 'dart:io';

import 'package:paxchange/src/config.dart';
import 'package:test/test.dart';

void main() {
  group('paxchange update', () {
    late Directory testDir;
    late Directory packageDir;

    late List<String> base1;
    late List<String> base2;
    late List<String> base3;
    late List<String> base4;
    final base5 = List.generate(10, (index) => 'fake-package-$index');

    File packageFile(String fileName) =>
        File.fromUri(packageDir.uri.resolve(fileName));

    Future<void> writePackages(String fileName, Iterable<String> lines) async =>
        packageFile(fileName).writeAsString(lines.join('\n'));

    Future<List<String>> readPackages(String fileName) async =>
        packageFile(fileName).readAsLines();

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
          'update',
          '--set-exit-on-changed',
        ],
        mode: ProcessStartMode.inheritStdio,
      );
      return proc.exitCode;
    }

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      packageDir = Directory.fromUri(testDir.uri.resolve('packages'));
      await packageDir.create();

      final packages = await _runPacman(const ['-Qqe']);
      final oneFourth = packages.length ~/ 4;
      base1 = packages.sublist(0, oneFourth);
      base2 = packages.sublist(oneFourth, oneFourth * 2);
      base3 = packages.sublist(oneFourth * 2, oneFourth * 3);
      base4 = packages.sublist(oneFourth * 3);

      await writePackages('base1', base1);
      await writePackages('base2', base2);
      await writePackages('base_all', [
        '::import base1',
        ...base3,
        '# other important packages',
        '::import ${packageDir.absolute.uri.resolve('base2').toFilePath()}',
      ]);
      await writePackages('machine-1', [
        '::import base_all',
        ...base4,
      ]);
      await writePackages('machine-2', [
        '::import base_all',
        ...base5,
      ]);
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    test('generates no changes by default', () async {
      final result = await runPaxchange('machine-1');

      expect(result, 0);

      final files = await packageDir.list().toList();
      expect(files, hasLength(5));
      expect(packageFile('machine-1.pcs').existsSync(), isFalse);
    });

    test('discards changes if no changes are actually left', () async {
      await writePackages('machine-1.pcs', <String>[
        ...base3.map((package) => '-$package'),
        ...base5.map((package) => '+$package'),
      ]);

      final result = await runPaxchange('machine-1');

      expect(result, 0);

      final files = await packageDir.list().toList();
      expect(files, hasLength(5));
      expect(packageFile('machine-1.pcs').existsSync(), isFalse);
    });

    test('generates changes if packages are different', () async {
      final result = await runPaxchange('machine-2');

      expect(result, 2);

      final files = await packageDir.list().toList();
      expect(files, hasLength(6));
      expect(packageFile('machine-2.pcs').existsSync(), isTrue);
      expect(
        await readPackages('machine-2.pcs'),
        unorderedEquals(<String>[
          ...base4.map((package) => '+$package'),
          ...base5.map((package) => '-$package'),
        ]),
      );
    });

    test(
        'detects changes but does not modify them '
        'if changes are already stored in pcs file', () async {
      await writePackages('machine-2.pcs', <String>[
        ...base4.map((package) => '+$package'),
        ...base5.map((package) => '-$package'),
      ]);

      final result = await runPaxchange('machine-2');

      expect(result, 2);

      final files = await packageDir.list().toList();
      expect(files, hasLength(6));
      expect(packageFile('machine-2.pcs').existsSync(), isTrue);
      expect(
        await readPackages('machine-2.pcs'),
        unorderedEquals(<String>[
          ...base4.map((package) => '+$package'),
          ...base5.map((package) => '-$package'),
        ]),
      );
    });

    test('updates changes if changes in pcs file are not accurate', () async {
      await writePackages('machine-2.pcs', <String>[
        ...base1.map((package) => '-$package'),
        ...base5.map((package) => '+$package-dev'),
      ]);

      final result = await runPaxchange('machine-2');

      expect(result, 2);

      final files = await packageDir.list().toList();
      expect(files, hasLength(6));
      expect(packageFile('machine-2.pcs').existsSync(), isTrue);
      expect(
        await readPackages('machine-2.pcs'),
        unorderedEquals(<String>[
          ...base4.map((package) => '+$package'),
          ...base5.map((package) => '-$package'),
        ]),
      );
    });
  });
}

Future<List<String>> _runPacman(List<String> command) async {
  final result = await Process.run('pacman', command);
  stderr.writeln(result.stderr);
  expect(result.exitCode, 0);
  return const LineSplitter().convert(result.stdout as String);
}
