import 'package:riverpod/riverpod.dart';

import 'pacman/pacman.dart';
import 'storage/package_file_adapter.dart';

// coverage:ignore-start
final packageInstallProvider = Provider(
  (ref) => PackageInstall(
    ref.watch(packageFileAdapterProvider),
    ref.watch(pacmanProvider),
  ),
);
// coverage:ignore-end

class PackageInstall {
  final PackageFileAdapter _packageFileAdapter;
  final Pacman _pacman;

  const PackageInstall(
    this._packageFileAdapter,
    this._pacman,
  );

  Future<int> installPackages(String machineName) async {
    final packages =
        await _packageFileAdapter.loadPackageFile(machineName).toList();
    return _pacman.installPackages(packages, onlyNeeded: true);
  }
}
