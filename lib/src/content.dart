import 'dart:convert' show json;

class ContentException implements Exception {
  String cause;

  ContentException(this.cause);
}

abstract class Content {
  String get string;
  Map<String, Object> get map;
}

class JsonContent implements Content {
  Map<String, Object> _content;

  JsonContent(String content) {
    if (content.trim().isEmpty) {
      _content = const {};
    } else {
      _content = json.decode(content);
    }
  }

  String get string => json.encode(_content);

  Map<String, Object> get map => _content;
}
