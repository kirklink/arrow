import 'dart:io';

import 'package:arrow/src/context.dart';
import 'package:arrow/src/manager.dart';
import 'package:arrow/src/global.dart';

class MessageException implements Exception {
  final String message;

  MessageException(this.message);

  String toString() => 'MessageException: $message';
}

abstract class Message {
  HttpRequest _innerRequest;
  Manager _manager;
  Context _context;
  Global _global = Global();

  Message(HttpRequest this._innerRequest, {Manager manager, Context context}) {
    _manager = manager != null ? manager : Manager(_innerRequest);
    _context = context != null ? context : Context();
  }

  HttpRequest get innerRequest => _innerRequest;

  Context get context => _context;

  Manager get manager => _manager;

  Global get global => _global;

  bool get isAlive => _manager != null ? _manager.isAlive : false;

  Map<String, Object> get env => _global.variables.get('ENV');

  bool get isOnProd => env['ARROW_ENVIRONMENT'] == 'production';

  T backends<T>() => _global.variables.get<T>('BACKENDS');
}
