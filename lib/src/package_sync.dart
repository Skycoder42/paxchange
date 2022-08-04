import 'dart:collection';

import 'package:riverpod/riverpod.dart';

import 'config.dart';
import 'diff_entry.dart';
import 'pacman/pacman.dart';
import 'storage/diff_file_adapter.dart';
import 'storage/package_file_adapter.dart';

// coverage:ignore-start
final packageSyncProvider = Provider(
  (ref) => PackageSync(
    ref.watch(configProvider).rootPackageFile,
    ref.watch(packageFileAdapterProvider),
    ref.watch(diffFileAdapterProvider),
    ref.watch(pacmanProvider),
  ),
);
// coverage:ignore-end

class PackageSync {
  final String _rootPackageName;
  final PackageFileAdapter _packageFileAdapter;
  final DiffFileAdapter _diffFileAdapter;
  final Pacman _pacman;

  PackageSync(
    this._rootPackageName,
    this._packageFileAdapter,
    this._diffFileAdapter,
    this._pacman,
  );

  Future<int> updatePackageDiff() async {
    // load package history
    final packageHistory =
        await _packageFileAdapter.loadPackageFile(_rootPackageName).toSet();

    // load installed packages
    final installedPackages =
        await _pacman.listExplicitlyInstalledPackages().toSet();

    // create diff entries
    final diffEntries = SplayTreeSet<DiffEntry>();
    installedPackages
        .difference(packageHistory)
        .map(DiffEntry.added)
        .forEach(diffEntries.add);
    packageHistory
        .difference(installedPackages)
        .map(DiffEntry.removed)
        .forEach(diffEntries.add);

    // write diff file
    await _diffFileAdapter.savePackageDiff(_rootPackageName, diffEntries);
    return diffEntries.length;
  }
}
