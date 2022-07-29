import 'dart:collection';

import 'package:riverpod/riverpod.dart';

import 'diff_entry.dart';
import 'pacman/pacman.dart';
import 'storage/diff_file_adapter.dart';
import 'storage/package_file_adapter.dart';

final packageSyncProvider = Provider(
  (ref) => PackageSync(
    ref.watch(packageFileAdapterProvider),
    ref.watch(diffFileAdapterProvider),
    ref.watch(pacmanProvider),
  ),
);

class PackageSync {
  final PackageFileAdapter _packageFileAdapter;
  final DiffFileAdapter _diffFileAdapter;
  final Pacman _pacman;

  PackageSync(
    this._packageFileAdapter,
    this._diffFileAdapter,
    this._pacman,
  );

  Future<int> updatePackageDiff(String machineName) async {
    // load package history
    final packageHistory =
        await _packageFileAdapter.loadPackageFile(machineName).toSet();

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
    await _diffFileAdapter.savePackageDiff(machineName, diffEntries);
    return diffEntries.length;
  }
}
