class InternalMessenger {
  final _messages = List<String>();
  final _errors = List<String>();
  
  List<String> get messages => _messages;
  List<String> get errors => _errors;

  addMessage(String message) {
    _messages.add(message);
  }

  addError(String message) {
    _errors.add(message);
  }
}