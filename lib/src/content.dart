import 'dart:convert' show json;

// TODO: just make this handle json only

class ContentException implements Exception {
  String cause;

  ContentException(this.cause);
}

abstract class Content {
  String get string;

  Map<String, Object> get map;

  String encode();
}

class JsonContent implements Content {
  Map<String, Object> _content;

  JsonContent(String content) {
    _content = json.decode(content);
  }

  String get string => null;

  Map<String, Object> get map => _content;

  String encode() {
    return json.encode(_content);
  }

}
