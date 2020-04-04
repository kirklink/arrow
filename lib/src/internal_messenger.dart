class InternalMessenger {
  List<String> _messages = List<String>();
  List<String> get list => _messages;
  String get string => _messages.join(' | ');

  add(String message) {
    _messages.add(message);
  }
}