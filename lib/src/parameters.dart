class ParametersException implements Exception {
  String cause;

  ParametersException(this.cause);
}

class Parameters {
  Map<String, String> _parameters;

  String get(String key) {
    if (!_parameters.containsKey(key)) return null;
    return _parameters[key];
  }

  void load(Map<String, String> srcParameters) {
    if (_parameters != null)
      throw ParametersException('Parameters already loaded.');
    _parameters = Map<String, String>.from(srcParameters);
  }
}
