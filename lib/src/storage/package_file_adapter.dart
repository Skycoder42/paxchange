import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config.dart';
import '../pacman/pacman.dart';
import 'package_file_hierarchy.dart';

part 'package_file_adapter.g.dart';

// coverage:ignore-start
@riverpod
PackageFileAdapter packageFileAdapter(Ref ref) => PackageFileAdapter(
  ref.watch(configProvider).storageDirectory,
  ref.watch(pacmanProvider),
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
  static final _groupRegExp = RegExp(r'^::group\s+(\S.*)$');

  final Directory _storageDirectory;
  final Pacman _pacman;

  PackageFileAdapter(this._storageDirectory, this._pacman);

  Stream<String> loadPackageFile(
    String machineName, {
    bool expandGroups = true,
  }) {
    final packageFile = _packageFile(machineName);

    if (packageFile.existsSync()) {
      return _streamPackageFile(packageFile, {machineName}, expandGroups);
    } else {
      return const Stream.empty();
    }
  }

  Future<PackageFileHierarchy> loadPackageFileHierarchy(
    String machineName,
  ) async {
    final packageFile = _packageFile(machineName);
    if (packageFile.existsSync()) {
      // ignore: prefer_collection_literals sorting is relevant
      final packageFiles = LinkedHashSet<String>();
      final groupsByPackages = <String, Set<String>>{};
      final missingGroups = <String>{};
      await _loadPackageFileHierarchyRecursively(
        packageFile: packageFile,
        packageFiles: packageFiles,
        groupsByPackages: groupsByPackages,
        missingGroups: missingGroups,
        importHistory: {machineName},
      );
      return PackageFileHierarchy(
        packageFiles: packageFiles,
        groupsByPackages: groupsByPackages,
        missingGroups: missingGroups,
      );
    } else {
      return PackageFileHierarchy.empty;
    }
  }

  Future<void> ensurePackageFileExists(String machineName) async {
    final packageFile = _packageFile(machineName);
    if (!packageFile.existsSync()) {
      await packageFile.create();
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
    String package, {
    bool recursive = true,
    bool isGroup = false,
    List<String> replacement = const [],
  }) async {
    final packageFile = _packageFile(machineName);
    if (!packageFile.existsSync()) {
      return false;
    }

    return await _removePackageRecursively(
      packageFile,
      package,
      {machineName},
      recursive,
      isGroup,
      replacement,
    );
  }

  File _packageFile(String machineName) =>
      File.fromUri(_storageDirectory.uri.resolve(machineName));

  Stream<String> _streamPackageFile(
    File packageFile,
    Set<String> importHistory,
    bool expandGroups,
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
          expandGroups,
        );
        continue;
      }

      // replace groups with their packages
      final groupMatch = _groupRegExp.matchAsPrefix(line);
      if (groupMatch != null) {
        final groupName = groupMatch[1]!;
        if (expandGroups) {
          yield* _pacman.listPackagesForGroup(groupName, ignoreErrors: true);
        } else {
          yield groupName;
        }
        continue;
      }

      // simply yield normal entries
      yield line;
    }
  }

  Future<void> _loadPackageFileHierarchyRecursively({
    required File packageFile,
    required Set<String> packageFiles,
    required Map<String, Set<String>> groupsByPackages,
    required Set<String> missingGroups,
    required Set<String> importHistory,
  }) async {
    assert(packageFile.existsSync(), '$packageFile must exist');

    packageFiles.add(
      isWithin(_storageDirectory.path, packageFile.path)
          ? relative(packageFile.path, from: _storageDirectory.path)
          : packageFile.absolute.path,
    );

    await for (final line in _streamLines(packageFile)) {
      // recursively stream imported package files
      final importMatch = _importRegExp.matchAsPrefix(line);
      if (importMatch != null) {
        final importFileName = importMatch[1]!;
        await _loadPackageFileHierarchyRecursively(
          packageFile: _findPackageFile(importFileName, packageFiles),
          packageFiles: packageFiles,
          groupsByPackages: groupsByPackages,
          missingGroups: missingGroups,
          importHistory: _updateHistory(importFileName, importHistory),
        );
        continue;
      }

      // collect groups per package
      final groupMatch = _groupRegExp.matchAsPrefix(line);
      if (groupMatch != null) {
        final groupName = groupMatch[1]!;
        var foundAny = false;
        await for (final package in _pacman.listPackagesForGroup(
          groupName,
          ignoreErrors: true,
        )) {
          foundAny = true;
          groupsByPackages.update(
            package,
            (groups) => groups..add(groupName),
            ifAbsent: () => {groupName},
          );
        }

        if (!foundAny) {
          missingGroups.add(groupName);
        }
        continue;
      }

      // skip packages
    }
  }

  Future<bool> _removePackageRecursively(
    File packageFile,
    String package,
    Set<String> importHistory,
    bool recursive,
    bool isGroup,
    List<String> replacement,
  ) async {
    assert(packageFile.existsSync(), '$packageFile must exist');

    final checkedLines = <String>[];
    var didRemove = false;
    await for (final rawLine in _streamLines(packageFile, autoTrim: false)) {
      checkedLines.add(rawLine);
      if (didRemove) {
        continue;
      }

      final line = rawLine.trim();

      // skip empty and comment lines
      if (line.isEmpty || _isComment(line)) {
        continue;
      }

      // recursively stream imported package files
      if (recursive) {
        final importMatch = _importRegExp.matchAsPrefix(line);
        if (importMatch != null) {
          final importFileName = importMatch[1]!;
          didRemove = await _removePackageRecursively(
            _findPackageFile(importFileName, importHistory),
            package,
            _updateHistory(importFileName, importHistory),
            true,
            isGroup,
            replacement,
          );

          if (didRemove) {
            return didRemove;
          } else {
            continue;
          }
        }
      }

      // groups are not processed
      if (isGroup) {
        final groupMatch = _groupRegExp.matchAsPrefix(line);
        if (groupMatch != null) {
          final groupName = groupMatch[1]!;
          if (groupName == package) {
            checkedLines.removeLast();
            didRemove = true;
          } else {
            continue;
          }
        }
      }

      // skip line if found and mark as removed
      if (!isGroup && line == package) {
        checkedLines.removeLast();
        didRemove = true;
      }
    }

    if (didRemove) {
      final sink = packageFile.openWrite();
      try {
        checkedLines.followedBy(replacement).forEach(sink.writeln);
      } finally {
        await sink.flush();
        await sink.close();
      }
    }

    return didRemove;
  }

  File _findPackageFile(String fileName, Iterable<String> history) {
    final packageFile = File.fromUri(_storageDirectory.uri.resolve(fileName));

    if (!packageFile.existsSync()) {
      throw LoadPackageFailure(
        fileName: fileName,
        history: history,
        message: 'Package file does not exist',
      );
    }

    return packageFile;
  }

  Stream<String> _streamLines(File packageFile, {bool autoTrim = true}) {
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
