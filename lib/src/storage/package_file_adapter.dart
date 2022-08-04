import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
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

  Stream<String> loadPackageFileHierarchy(String machineName) {
    final packageFile = _packageFile(machineName);

    if (packageFile.existsSync()) {
      return _streamPackageFileHierarchy(packageFile, {machineName});
    } else {
      return const Stream.empty();
    }
  }

  Future<void> addToPackageFile(String machineName, String package) async {
    final packageFile = _packageFile(machineName);

    final packageFileSink = packageFile.openWrite(
      mode: FileMode.writeOnlyAppend,
    );
    try {
      packageFileSink.writeln(package);
    } finally {
      await packageFileSink.flush();
      await packageFileSink.close();
    }
  }

  Future<bool> removeFromPackageFile(
    String machineName,
    String package,
  ) async {
    final packageFile = _packageFile(machineName);
    if (!packageFile.existsSync()) {
      return false;
    }

    final fileWithPackage = await _findPackageRecursively(
      packageFile,
      package,
      {machineName},
    );

    if (fileWithPackage == null) {
      return false;
    }

    final lines = await _streamLines(fileWithPackage, autoTrim: false).toList();
    final sink = fileWithPackage.openWrite();
    try {
      for (final line in lines) {
        if (line.trim() == package) {
          continue;
        }
        sink.writeln(line);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    return true;
  }

  File _packageFile(String machineName) => File.fromUri(
        _storageDirectory.uri.resolve(machineName),
      );

  Stream<String> _streamPackageFile(
    File packageFile,
    Set<String> importHistory,
  ) async* {
    assert(packageFile.existsSync(), '$packageFile must exist');

    await for (final line in _streamLines(packageFile)) {
      // skip comment lines
      if (_isComment(line)) {
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

  Stream<String> _streamPackageFileHierarchy(
    File packageFile,
    Set<String> importHistory,
  ) async* {
    assert(packageFile.existsSync(), '$packageFile must exist');

    if (isWithin(_storageDirectory.path, packageFile.path)) {
      yield relative(packageFile.path, from: _storageDirectory.path);
    } else {
      yield packageFile.absolute.path;
    }

    await for (final line in _streamLines(packageFile)) {
      // recursively stream imported package files
      final importMatch = _importRegExp.matchAsPrefix(line);
      if (importMatch != null) {
        final importFileName = importMatch[1]!;
        yield* _streamPackageFileHierarchy(
          _findPackageFile(importFileName, importHistory),
          _updateHistory(importFileName, importHistory),
        );
      }
    }
  }

  Future<File?> _findPackageRecursively(
    File packageFile,
    String package,
    Set<String> importHistory,
  ) async {
    assert(packageFile.existsSync(), '$packageFile must exist');

    await for (final line in _streamLines(packageFile)) {
      // skip comment lines
      if (_isComment(line)) {
        continue;
      }

      // recursively stream imported package files
      final importMatch = _importRegExp.matchAsPrefix(line);
      if (importMatch != null) {
        final importFileName = importMatch[1]!;
        final fileWithPackage = await _findPackageRecursively(
          _findPackageFile(importFileName, importHistory),
          package,
          _updateHistory(importFileName, importHistory),
        );

        if (fileWithPackage != null) {
          return fileWithPackage;
        }
      }

      // return with current file if found
      if (line == package) {
        return packageFile;
      }
    }

    return null;
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

  Stream<String> _streamLines(
    File packageFile, {
    bool autoTrim = true,
  }) {
    final rawLines = packageFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    if (!autoTrim) {
      return rawLines;
    }

    return rawLines.map((line) => line.trim()).where((line) => line.isNotEmpty);
  }

  bool _isComment(String line) => line.startsWith('#');

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
