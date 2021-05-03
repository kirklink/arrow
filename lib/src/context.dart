import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

class Context<T> {
  final _items = <String, dynamic>{};

  T trySet<T>(String key, T value) {
    if (_items.containsKey(key)) {
      return null;
    }
    _items[key] = value;
    return value;
  }

  // T replace<T>(String key, T value) {
  //   if (!_items.containsKey(key)) {
  //     throw ArrowException('The context key "$key" does not exist.');
  //   }
  //   _items[key] = value;
  //   return value;
  // }

  T setOrReplace<T>(String key, T value) {
    _items[key] = value;
    return value;
  }

  // T get<T>(String key) {
  //   if (!_items.containsKey(key)) {
  //     throw ArrowException('The context key "$key" does not exist.');
  //   }
  //   return _items[key];
  // }

  T tryGet<T>(String key) {
    if (!_items.containsKey(key)) return null;
    return _items[key];
  }

  T getOrSet<T>(String key, T value) {
    return _items.putIfAbsent(key, () => value);
  }

  // T delete<T>(String key) {
  //   if (!_items.containsKey(key)) {
  //     throw ArrowException('The context key "$key" does not exist.');
  //   }
  //   ;
  //   if (_items.containsKey(key)) {
  //     var i = get<T>(key);
  //     _items.remove(key);
  //     return i;
  //   }
  //   return null;
  // }

  T tryDelete<T>(String key) {
    if (_items.containsKey(key)) {
      final i = tryGet<T>(key);
      _items.remove(key);
      return i;
    }
    return null;
  }

  bool has(String key) {
    return _items.containsKey(key);
  }

  static String makeKey() {
    final uuid = Uuid(options: {'gnrg': UuidUtil.cryptoRNG()}).v4();
    return uuid;
  }
}
