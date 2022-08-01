import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../config.dart';
import '../diff_entry.dart';

// coverage:ignore-start
final diffFileAdapterProvider = Provider(
  (ref) => DiffFileAdapter(
    ref.watch(configProvider).storageDirectory,
  ),
);
// coverage:ignore-end

class DiffFileAdapter {
  final Directory _storageDirectory;

  DiffFileAdapter(this._storageDirectory);

  Stream<DiffEntry> loadPackageDiff(String machineName) {
    final diffFile = _diffFile(machineName);

    if (diffFile.existsSync()) {
      return _readDiffFile(diffFile);
    } else {
      return const Stream.empty();
    }
  }

  Future<void> savePackageDiff(
    String host,
    Set<DiffEntry> diffEntries,
  ) async {
    await _storageDirectory.create(recursive: true);

    final diffFile = _diffFile(host);

    if (diffEntries.isEmpty) {
      if (diffFile.existsSync()) {
        await diffFile.delete();
      }
      return;
    }

    final diffFileSink = diffFile.openWrite();
    try {
      for (final entry in diffEntries) {
        diffFileSink.writeln(entry.encode());
      }

      await diffFileSink.flush();
    } finally {
      await diffFileSink.close();
    }
  }

  File _diffFile(String host) => File.fromUri(
        _storageDirectory.uri.resolve('$host.pcs'),
      );

  Stream<DiffEntry> _readDiffFile(File diffFile) {
    assert(diffFile.existsSync(), '$diffFile must exist');
    return diffFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map(DiffEntry.decode);
  }
}
