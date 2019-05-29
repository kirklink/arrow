import 'dart:io';

import 'package:arrow/src/context.dart';
import 'package:arrow/src/manager.dart';


class MessageException implements Exception {
  final String message;

  MessageException(this.message);

  String toString() => 'MessageException: $message';
}

abstract class Message {
  HttpRequest _innerRequest;
  Manager _manager;
  Context _context;


  Message(HttpRequest this._innerRequest, {Manager manager, Context context}) {
    _manager = manager != null ? manager : Manager(_innerRequest);
    _context = context != null ? context : Context();
  }

  HttpRequest get innerRequest => _innerRequest;

  Context get context => _context;

  Manager get manager => _manager;

  bool get isAlive => _manager != null ? _manager.isAlive : false;

}
