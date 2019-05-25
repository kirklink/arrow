import 'dart:io';

class Messenger {
  List<String> _messages = List<String>();

  List<String> get list => _messages;

  String get string => _messages.join(' | ');

  add(String message) {
    _messages.add(message);
  }
}

class Manager {
  bool _isAlive = true;
  HttpRequest _innerRequest;
  final Messenger messages = Messenger();
  final Messenger errorMessages = Messenger();

  Manager(HttpRequest this._innerRequest) {
    _innerRequest.response.done.whenComplete(() {
      _isAlive = false;
    });
  }

  bool get isAlive => _isAlive;

  abort() {
    // await _innerRequest.response.close();
    _isAlive = false;
  }
}
