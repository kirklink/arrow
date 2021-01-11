class GetterSetterException implements Exception {
  final String message;

  GetterSetterException(this.message);

  String toString() => 'GetterSetterException: $message';
}

class GetterSetter<T> {
  Map<String, Object> _items = {};

  T set<T>(String key, T value) {
    if (_items.containsKey(key)) {
      throw GetterSetterException('The key "$key" already exists.');
    }
    _items[key] = value;
    return value;
  }

  T replace<T>(String key, T value) {
    if (!_items.containsKey(key)) {
      throw GetterSetterException('The key "$key" does not exist.');
    }
    ;
    _items[key] = value;
    return value;
  }

  T setOrReplace<T>(String key, T value) {
    _items[key] = value;
    return value;
  }

  T get<T>(String key) {
    if (!_items.containsKey(key)) {
      throw GetterSetterException('The key "$key" does not exist.');
    }
    ;
    return _items[key];
  }

  T tryGet<T>(String key) {
    if (!_items.containsKey(key)) return null;
    return _items[key];
  }

  T getOrSet<T>(String key, T value) {
    if (_items.containsKey(key)) {
      return get<T>(key);
    } else {
      return set(key, value);
    }
  }

  T delete<T>(String key) {
    if (!_items.containsKey(key)) {
      throw GetterSetterException('The key "$key" does not exist.');
    }
    ;
    if (_items.containsKey(key)) {
      var i = get<T>(key);
      _items.remove(key);
      return i;
    }
    return null;
  }

  T tryDelete<T>(String key) {
    if (_items.containsKey(key)) {
      var i = get<T>(key);
      _items.remove(key);
      return i;
    }
    return null;
  }

  bool has(String key) {
    return _items.containsKey(key);
  }
}
