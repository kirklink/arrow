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

  JsonContent(this._content);

  String get string => null;

  Map<String, Object> get map => _content;
}
