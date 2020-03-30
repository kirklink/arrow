class GetterSetterException implements Exception {
  final String message;

  GetterSetterException(this.message);

  String toString() => 'GetterSetterException: $message';
}


class Locker<T> {

  Map<String, Object> _items = {};

  T set<T>(String key, T value) {
    if (_items.containsKey(key)) return null;
    _items[key] = value;
    return value;
  }

  T replace<T>(String key, T value) {
    if (!_items.containsKey(key)) return null;
    _items[key] = value;
    return value;
  }

  T get<T>(String key) {
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

  void load(Map<String, Object> items) {
    if (_items.isNotEmpty)
      throw GetterSetterException('Can only load into an empty GetterSetter.');
    for (var i in items.keys) {
      set(i, items[i]);
    }
  }
}
