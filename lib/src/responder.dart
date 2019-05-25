import 'dart:io';
import 'dart:convert' show jsonEncode;

import 'package:arrow/src/manager.dart';

class Responder {
  HttpRequest _request;
  HttpResponse _response;
  Manager _manager;
  String _wrapper = 'data';
  bool _isWrapped = true;

  Responder(HttpRequest this._request, Manager this._manager,
      {bool isWrapped, String wrapper}) {
    _response = _request.response;
    _setWrapper(wrapper, isWrapped);
  }

  _setWrapper(String wrapper, bool isWrapped) {
    if (wrapper != null) _wrapper = wrapper;
    if (isWrapped != null) _isWrapped = isWrapped;
  }

  Map<String, Object> _wrapResponse(Map<String, Object> base) {
    if (_isWrapped) return {_wrapper: base};
    return base;
  }

  void render(String message, {int statusCode}) {
    if (statusCode != null) {
      _response.statusCode = statusCode;
    } else {
      _setSuccessHeaders();
    }
    _response.statusCode = HttpStatus.ok;
    _response.write(message);
  }

  void ok(Map<String, Object> message,
      {int statusCode, String wrapper, bool wrapped}) {
    _setWrapper(wrapper, wrapped);
    if (statusCode != null) {
      _response.statusCode = statusCode;
    } else {
      _setSuccessHeaders();
    }
    _setJsonHeader();
    _writeToJson(_wrapResponse(message));
  }

  void success() {
    _setSuccessHeaders();
    _setJsonHeader();
  }

  void unauthorized() {
    _response.statusCode = HttpStatus.unauthorized;
    _manager.abort();
  }

  void notFound() {
    _response.statusCode = HttpStatus.notFound;
    _manager.abort();
  }

  void badRequest(
      {Map<String, Object> errors,
      String message,
      String wrapper,
      bool wrapped}) {
    _setWrapper(wrapper, wrapped);
    _response.statusCode = HttpStatus.badRequest;
    if (errors != null && message != null)
      throw Exception('Only one of "errors" or "message" can be provided.');
    if (errors != null) {
      _setJsonHeader();
      _writeToJson(_wrapResponse(errors));
    } else if (message != null) {
      _setJsonHeader();
      var m = {'errorMessage': message};
      _writeToJson(_wrapResponse(m));
    }
    _manager.abort();
  }

  void serverError() {
    _response.statusCode = HttpStatus.internalServerError;
    _manager.abort();
  }

  void redirect(Uri location, {int statusCode}) {
    _response.redirect(location, status: statusCode);
    _manager.abort();
  }

  void _setJsonHeader() {
    _response.headers.contentType = ContentType.json;
  }

  void _writeToJson(Map<String, Object> message) {
    _response.write(jsonEncode(message));
  }

  void _setSuccessHeaders() {
    if (_request.method == 'POST') {
      _response.statusCode = HttpStatus.created;
    } else if (_request.method == 'DELETE') {
      _response.statusCode = HttpStatus.noContent;
    } else {
      _response.statusCode = HttpStatus.ok;
    }
  }
}
