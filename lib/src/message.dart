import 'dart:io' as io;

import 'package:arrow/src/context.dart';
import 'package:arrow/src/internal_messenger.dart';


class MessageException implements Exception {
  final String message;

  MessageException(this.message);

  String toString() => 'MessageException: $message';
}

abstract class Message {
  io.HttpRequest _innerRequest;
  Context _context;
  InternalMessenger _messenger;
  bool _isAlive;


  Message(this._innerRequest, this._isAlive, [InternalMessenger messenger, Context context]) {
    _messenger = messenger ?? InternalMessenger;
    _context = context ?? Context();
  }

  io.HttpRequest get innerRequest => _innerRequest;

  Context get context => _context;

  InternalMessenger get messenger => _messenger;

  bool get isOnProd => io.Platform.environment['ARROW_ENVIRONMENT'] == 'production';

  bool get isAlive => _isAlive;

  void cancel() {
    _isAlive = false;
  }

}
