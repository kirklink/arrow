import 'dart:io' as io;

import 'package:arrow/src/arrow.dart';
import 'package:arrow/src/context.dart';
import 'package:arrow/src/internal_messenger.dart';

class MessageException implements Exception {
  final String message;

  MessageException(this.message);

  String toString() => 'MessageException: $message';
}

class Alive {
  bool _isAlive = true;

  Alive();

  bool get isAlive => _isAlive;

  void kill() {
    _isAlive = false;
  }
}

abstract class Message {
  io.HttpRequest _innerRequest;
  Context _context;
  InternalMessenger _messenger;
  Alive _alive;

  Message(this._innerRequest,
      [InternalMessenger messenger, Context context, Alive alive]) {
    _messenger = messenger ?? InternalMessenger();
    _context = context ?? Context();
    _alive = alive ?? Alive();
  }

  io.HttpRequest get innerRequest => _innerRequest;

  Context get context => _context;
  Alive get alive => _alive;
  InternalMessenger get messenger => _messenger;

  bool get isOnProd => Arrow.isOnProduction;
  bool get isOnStage => Arrow.isOnStaging;
  bool get isOnDev => Arrow.isOnDevelopment;
  String get environment => Arrow.environment;

  bool get isAlive => _alive.isAlive;

  void cancel() {
    _alive.kill();
  }
}
