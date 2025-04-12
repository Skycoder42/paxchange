import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'pacman/pacman.dart';

part 'package_cleanup.g.dart';

// coverage:ignore-start
@riverpod
PackageCleanup packageCleanup(Ref ref) =>
    PackageCleanup(ref.watch(pacmanProvider));
// coverage:ignore-end

class PackageCleanup {
  final Pacman _pacman;

  const PackageCleanup(this._pacman);

  Future<int> removePackages({
    bool includeOptional = false,
    bool noConfirm = false,
  }) async {
    final packages =
        await _pacman
            .listUnusedPackages(includeOptional: includeOptional)
            .toList();

    return await _pacman.removeAllPackage(packages, noConfirm: noConfirm);
  }
}
