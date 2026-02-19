class ParametersException implements Exception {
  String cause;

  ParametersException(this.cause);
}

class Parameters {
  final _parameters = <String, String>{};

  /// Get a path parameter value by key.
  ///
  /// Returns the parameter value as a [String], or `null` if the parameter
  /// does not exist. This allows callers to distinguish between a missing
  /// parameter and an empty string value.
  ///
  /// ```dart
  /// // Route: /users/{id}
  /// // Request: /users/42
  /// final id = req.params.get('id');       // '42'
  /// final missing = req.params.get('foo'); // null
  /// ```
  String? get(String key) {
    return _parameters[key];
  }

  void load(Map<String, String> srcParameters) {
    if (_parameters.isNotEmpty)
      throw ParametersException('Parameters already loaded.');
    _parameters.addAll({
      for (final entry in srcParameters.entries)
        entry.key: Uri.decodeComponent(entry.value),
    });
  }
}
