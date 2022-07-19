import 'dart:collection';
import 'dart:math';

class OrderedList<T extends Comparable<T>> with ListMixin<T> {
  final _rawList = <T>[];

  @override
  int get length => _rawList.length;

  @override
  T operator [](int index) => _rawList[index];

  @override
  void add(T element) {
    final testIndex = _rawList.length ~/ 2;
    while (true) {
      final testItem = _rawList[testIndex];
      final compareResult = testItem.compareTo(element);
      if (compareResult == 0) {
        _rawList.insert(testIndex, element);
      }
    }
  }

  // make unmodifiable
  @override
  void operator []=(int index, T value) {
    _throwUnsupported('update elements');
  }

  @override
  set length(int newLength) {
    _throwUnsupported('change length');
  }

  @override
  set first(T value) {
    _throwUnsupported('update first');
  }

  @override
  set last(T value) {
    _throwUnsupported('update last');
  }

  @override
  void shuffle([Random? random]) {
    _throwUnsupported('shuffle');
  }

  @override
  void fillRange(int start, int end, [T? fill]) {
    _throwUnsupported('fill a range');
  }

  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    _throwUnsupported('set a range');
  }

  @override
  void replaceRange(int start, int end, Iterable<T> newContents) {
    _throwUnsupported('replace a range');
  }

  @override
  void insert(int index, T element) {
    _throwUnsupported('insert elements');
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    _throwUnsupported('insert elements');
  }

  @override
  void setAll(int index, Iterable<T> iterable) {
    _throwUnsupported('set all');
  }

  @override
  void sort([int Function(T a, T b)? compare]) {
    _throwUnsupported('sort');
  }

  Never _throwUnsupported(String operation) =>
      throw UnsupportedError('Cannot $operation in an ordered list directly.');
}
