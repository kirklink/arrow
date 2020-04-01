import 'dart:io' as io;
import 'dart:convert' show jsonEncode;

class ResponseManagerException implements Exception {
  String cause;
  ResponseManagerException(this.cause);
}

class Messenger {
  List<String> _messages = List<String>();
  List<String> get list => _messages;
  String get string => _messages.join(' | ');

  add(String message) {
    _messages.add(message);
  }
}

class ResponseParts {
  int _statusCode;
  io.ContentType _contentType = io.ContentType.json;
  String _body;
  Uri _redirect;
}

class Manager {
  bool _isAlive = true;
  io.HttpRequest _innerRequest;
  final Messenger messages = Messenger();
  final Messenger errorMessages = Messenger();
  ResponseParts _responseParts = ResponseParts();
  bool _isWrapped;
  String _wrapper;

  Manager(io.HttpRequest this._innerRequest) {
    _innerRequest.response.done.whenComplete(() {
      _isAlive = false;
    });
  }

  bool get isAlive => _isAlive;
  
  abort() {
    _isAlive = false;
  }

  int get statusCode => _responseParts._statusCode;

  bool isComplete() {
    if (_responseParts._statusCode != null
        && ((_responseParts._contentType != null && _responseParts._body != null) 
        || (_responseParts._redirect != null))) {
      return true;
    } else {
      return false;
    }
  }

  void setWrapper(bool isWrapped, String wrapper) {
    _isWrapped = isWrapped;
    _wrapper = wrapper;
  }

  void setSuccess(Map<String, Object> msg, {int statusCode, bool override:false}) {
    if (override) {
      _responseParts = ResponseParts();
    } else if (isComplete() && !override) {
      throw ResponseManagerException('Cannot modify a completed response without override.');
    }
    if (statusCode == null) {
      if (_innerRequest.method == 'POST') {
      _responseParts._statusCode = io.HttpStatus.created;
      } else if (_innerRequest.method == 'DELETE') {
        _responseParts._statusCode = io.HttpStatus.noContent;
      } else {
        _responseParts._statusCode = io.HttpStatus.ok;
      }
    } else {
      _responseParts._statusCode = statusCode;
    }
    _writeToJson(msg);
  }

  void setError(int statusCode, {Map<String, Object> errors, bool override:false}) {
    if (override) {
      _responseParts = ResponseParts();
    } else if (isComplete() && !override) {
      throw ResponseManagerException('Cannot modify a completed response without override.');
    }
    _responseParts._statusCode = statusCode;
    _writeToJson(errors ?? {});
    abort();
  }

  void setRedirect(Uri location, bool permanent, {bool override:false}) {
    if (override) {
      _responseParts = ResponseParts();
    } else if (isComplete() && !override) {
      throw ResponseManagerException('Cannot modify a completed response without override.');
    }
    _responseParts._redirect = location;
    if (permanent) {
      _responseParts._statusCode = io.HttpStatus.permanentRedirect;
    } else {
      _responseParts._statusCode = io.HttpStatus.temporaryRedirect;
    }
  }

  Map<String, Object> _wrapResponse(Map<String, Object> base) {
    if (_isWrapped) {
      return {_wrapper: base};
    } else {
      return base;
    }
  }

  void _writeToJson(Map<String, Object> message) {
    _responseParts._body = (jsonEncode(_wrapResponse(message)));
  }

  void complete() {
    _innerRequest.response.headers.contentType = _responseParts._contentType;
    _innerRequest.response.statusCode = _responseParts._statusCode;
    if (_responseParts._body.isNotEmpty) {
      _innerRequest.response.write(_responseParts._body);
    }
  }


}
