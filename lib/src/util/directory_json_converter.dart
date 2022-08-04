import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

class DirectoryJsonConverter implements JsonConverter<Directory, String> {
  const DirectoryJsonConverter();

  @override
  Directory fromJson(String json) => Directory(json);

  @override
  String toJson(Directory directory) => directory.path;
}
