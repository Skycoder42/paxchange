import 'package:riverpod/riverpod.dart';

import '../diff_entry.dart';
import 'diff_file_adapter.dart';
import 'package_file_adapter.dart';

class _DiffCollection {
  final List<String> added;
  final List<String> removed;

  const _DiffCollection({
    required this.added,
    required this.removed,
  });
}

final storageAdapterProvider = Provider(
  (ref) => StorageAdapter(
    ref.watch(packageFileAdapterProvider),
    ref.watch(diffFileAdapterProvider),
  ),
);

class StorageAdapter {
  final PackageFileAdapter _packageFileAdapter;
  final DiffFileAdapter _diffFileAdapter;

  StorageAdapter(
    this._packageFileAdapter,
    this._diffFileAdapter,
  );

  Stream<String> loadPackageHistory(String machineName) {
    final packageStream = _packageFileAdapter.loadPackageFile(machineName);

    if (_diffFileAdapter.hasPackageDiff(machineName)) {
      return _mergePackageDiff(machineName, packageStream);
    } else {
      return packageStream;
    }
  }

  Future<void> savePackageDiff(
    String machineName,
    Iterable<DiffEntry> diffEntries,
  ) =>
      _diffFileAdapter.savePackageDiff(machineName, diffEntries);

  Stream<String> _mergePackageDiff(
    String machineName,
    Stream<String> packageStream,
  ) async* {
    // load diff
    final diffCollection = await _splitCollectDiffEntries(
      _diffFileAdapter.loadPackageDiff(machineName),
    );

    // stream all packages except the removed ones
    yield* packageStream.where(
      (package) => !diffCollection.removed.contains(package),
    );

    // stream the remaining added ones
    yield* Stream.fromIterable(diffCollection.added);
  }

  Future<_DiffCollection> _splitCollectDiffEntries(
    Stream<DiffEntry> stream,
  ) async {
    final added = <String>[];
    final removed = <String>[];

    await for (final diffEntry in stream) {
      diffEntry.when(
        added: added.add,
        removed: removed.add,
      );
    }

    return _DiffCollection(added: added, removed: removed);
  }
}
