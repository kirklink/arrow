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
      final c = json.decode(content);
      if (c is Map) {
        _content = c;
      } else if (c is List) {
        _content['data'] = _content;
      } else {
        throw FormatException('Body is not an object or list.');
      }
    }
  }

  String get string => json.encode(_content);

  Map<String, Object> get map => _content;
}
