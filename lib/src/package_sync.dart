import 'dart:collection';

import 'package:riverpod/riverpod.dart';

import 'diff_entry.dart';
import 'pacman/pacman.dart';
import 'storage/storage_adapter.dart';

final packageSyncProvider = Provider(
  (ref) => PackageSync(
    ref.watch(storageAdapterProvider),
    ref.watch(pacmanProvider),
  ),
);

class PackageSync {
  final StorageAdapter _storageAdapter;
  final Pacman _pacman;

  PackageSync(
    this._storageAdapter,
    this._pacman,
  );

  Future<int> updatePackageDiff(String machineName) async {
    // load package history
    final packageHistory =
        await _storageAdapter.loadPackageHistory(machineName).toSet();

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

    if (diffEntries.isEmpty) {
      return 0;
    }

    // write diff file
    await _storageAdapter.savePackageDiff(machineName, diffEntries);
    return diffEntries.length;
  }
}
