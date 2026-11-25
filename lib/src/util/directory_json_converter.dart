import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

class const DirectoryJsonConverter()
    implements JsonConverter<Directory, String> {
  @override
  Directory fromJson(String json) => Directory(json);

  @override
  String toJson(Directory directory) => directory.path;
}
