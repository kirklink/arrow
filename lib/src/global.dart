import 'package:bottom_line/getter_setter.dart';
import 'package:arrow/src/environment.dart';

class GlobalException implements Exception {
  final String message;

  GlobalException(String this.message);

  String toString() => 'GlobalException: $message';
}

class Global {
  GetterSetter _variables = GetterSetter();

  GetterSetter get variables => _variables;

  static Global _cache;

  Global._internal(Map<String, Object> variables) {
    variables.forEach((k, v) {
      _variables.set(k, v);
    });
  }

  factory Global([Map<String, Object> variables]) {
    if (_cache != null) return _cache;
    _cache = Global._internal(variables);
    return _cache;
  }

  T env<T extends Environment>() {
    return _variables.get('ENV_OBJ');
  }

}
