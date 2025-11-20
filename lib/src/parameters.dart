class ParametersException implements Exception {
  String cause;

  ParametersException(this.cause);
}

class Parameters {
  final _parameters = <String, String>{};

  String get(String key) {
    return _parameters[key] ?? '';
  }

  void load(Map<String, String> srcParameters) {
    if (_parameters.isNotEmpty)
      throw ParametersException('Parameters already loaded.');
    _parameters.addAll(Map<String, String>.from(srcParameters));
  }
}
