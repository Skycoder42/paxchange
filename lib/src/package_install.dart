import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'pacman/pacman.dart';
import 'storage/package_file_adapter.dart';

part 'package_install.g.dart';

// coverage:ignore-start
@riverpod
PackageInstall packageInstall(Ref ref) => PackageInstall(
  ref.watch(packageFileAdapterProvider),
  ref.watch(pacmanProvider),
);
// coverage:ignore-end

class PackageInstall {
  final PackageFileAdapter _packageFileAdapter;
  final Pacman _pacman;

  const PackageInstall(this._packageFileAdapter, this._pacman);

  Future<int> installPackages(
    String machineName, {
    bool noConfirm = false,
  }) async {
    final packages =
        await _packageFileAdapter
            .loadPackageFile(machineName, expandGroups: false)
            .toList();

    return _pacman.installPackages(
      packages,
      onlyNeeded: true,
      noConfirm: noConfirm,
    );
  }
}
