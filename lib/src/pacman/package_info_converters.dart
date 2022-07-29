import 'package:freezed_annotation/freezed_annotation.dart';

class PackageInfoStringListConvert
    implements JsonConverter<List<String>, String> {
  static const _emptyListKeyword = 'None';

  const PackageInfoStringListConvert();

  @override
  List<String> fromJson(String json) {
    if (json.isEmpty || json == _emptyListKeyword) {
      return const [];
    }

    return json.split('  ');
  }

  @override
  String toJson(List<String> list) =>
      list.isEmpty ? _emptyListKeyword : list.join('  ');
}

class PackageInfoIntConverter implements JsonConverter<int, String> {
  const PackageInfoIntConverter();

  @override
  int fromJson(String json) => int.parse(json);

  @override
  String toJson(int number) => number.toString();
}

class PackageInfoDoubleConverter implements JsonConverter<double, String> {
  const PackageInfoDoubleConverter();

  @override
  double fromJson(String json) => double.parse(json);

  @override
  String toJson(double number) => number.toString();
}
