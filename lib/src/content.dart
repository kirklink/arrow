

class ContentException implements Exception {
  final String _cause;

  ContentException(this._cause);

  @override
  String toString() => _cause;
}

// Interface definition for processed request content
abstract class Content {
  String get string;
  Map<String, Object> get map;
}


