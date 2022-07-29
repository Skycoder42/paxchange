import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../config.dart';

// coverage:ignore-start
final packageFileAdapterProvider = Provider(
  (ref) => PackageFileAdapter(
    ref.watch(configProvider).storageDirectory,
  ),
);
// coverage:ignore-end

class LoadPackageFailure implements Exception {
  final String fileName;
  final List<String> history;
  final String message;

  LoadPackageFailure({
    required this.fileName,
    required Iterable<String> history,
    required this.message,
  }) : history = history.toList();

  @override
  String toString() =>
      '$fileName: $message. Import history: ${history.join(' -> ')}';
}

class PackageFileAdapter {
  static final _importRegExp = RegExp(r'^::import\s+(\S.*)$');

  final Directory _storageDirectory;

  PackageFileAdapter(this._storageDirectory);

  Stream<String> loadPackageFile(String machineName) {
    final packageFile = _packageFile(machineName);

    if (packageFile.existsSync()) {
      return _streamPackageFile(packageFile, {machineName});
    } else {
      return const Stream.empty();
    }
  }

  Stream<String> loadPackageFileHierarchy(String machineName) =>
      throw UnimplementedError();

  Future<void> addToPackageFile(String machineName, String package) =>
      throw UnimplementedError();

  Future<void> removeFromPackageFile(String machineName, String package) =>
      throw UnimplementedError();

  File _packageFile(String machineName) => File.fromUri(
        _storageDirectory.uri.resolve(machineName),
      );

  Stream<String> _streamPackageFile(
    File packageFile,
    Set<String> importHistory,
  ) async* {
    assert(packageFile.existsSync(), '$packageFile must exist');

    final lines = packageFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    await for (final line in lines) {
      // skip comment lines
      if (line.startsWith('#')) {
        continue;
      }

      // recursively stream imported package files
      final importMatch = _importRegExp.matchAsPrefix(line);
      if (importMatch != null) {
        final importFileName = importMatch[1]!;
        yield* _streamPackageFile(
          _findPackageFile(importFileName, importHistory),
          _updateHistory(importFileName, importHistory),
        );
        continue;
      }

      // simply yield normal entries
      yield line;
    }
  }

  File _findPackageFile(String fileName, Iterable<String> history) {
    final packageFile = File.fromUri(
      _storageDirectory.uri.resolve(fileName),
    );

    if (!packageFile.existsSync()) {
      throw LoadPackageFailure(
        fileName: fileName,
        history: history,
        message: 'Package file does not exist',
      );
    }

    return packageFile;
  }

  Set<String> _updateHistory(String importFileName, Set<String> importHistory) {
    if (importHistory.contains(importFileName)) {
      throw LoadPackageFailure(
        fileName: importFileName,
        history: importHistory.followedBy([importFileName]),
        message: 'Circular import detected',
      );
    }

    return {...importHistory, importFileName};
  }
}
