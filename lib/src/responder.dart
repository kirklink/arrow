import 'dart:io' as io;
import 'dart:convert' show json;

import 'response.dart';
import 'request.dart';
import 'arrow_exception.dart';

class Responder {
  Request? _request;
  var _complete = false;
  Response? _response;

  Responder();

  // bool get isComplete => _responseObject != null;
  // int get statusCode => _responseObject.statusCode;
  //
  Response? get response => _response;

  Responder go(Request request) {
    if (_request == null) _request = request;
    return this;
  }

  Response? ok(
      {Map<String, dynamic> data = const <String, dynamic>{},
      bool printResponseObject = false}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = _getSuccessCode();
    final encoded = json.encode({"ok": true, "data": data});
    final srcResponse = _request!.innerRequest.response;
    srcResponse.headers.set(
        io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    srcResponse.statusCode = code;
    srcResponse.write(encoded);
    _complete = true;
    _response = Response(_request, data: data);
    return _response;
  }

  Response? raw(int statusCode, Map<String, dynamic> data) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final encoded = json.encode(data);
    final srcResponse = _request!.innerRequest.response;
    srcResponse.headers.set(
        io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    srcResponse.statusCode = statusCode;
    srcResponse.write(encoded);
    _complete = true;
    _response = Response(_request, data: data);
    return _response;
  }

  Response? code(int statusCode) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final srcResponse = _request!.innerRequest.response;
    srcResponse.statusCode = statusCode;
    _complete = true;
    _response = Response(_request);
    return _response;
  }

  Response? unauthorized(
      {String msg = 'Unauthorized',
      Map<String, Object> errors = const <String, String>{},
      bool printResponseObject = false}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.unauthorized;
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, errors as Map<String, String>));
    return _response;
  }

  Response? notFound(
      {String msg = 'Not Found',
      Map<String, Object> errors = const <String, String>{},
      bool printResponseObject = false}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.notFound;
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, errors as Map<String, String>));
    return _response;
  }

  Response? forbidden(
      {String msg = 'Forbidden',
      Map<String, Object> errors = const <String, String>{},
      bool printResponseObject = false}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.forbidden;
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, errors as Map<String, String>));
    return _response;
  }

  Response? badRequest(
      {String msg = 'Bad Request',
      Map<String, Object> errors = const <String, String>{},
      bool printResponseObject = false}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.badRequest;
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, errors as Map<String, String>));
    return _response;
  }

  Response? serverError() {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.internalServerError;
    final msg = 'Server Error';
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, const {}));
    return _response;
  }

  Request? _errorResponse(
      Request? request, int code, String msg, Map<String, String> errors) {
    final wrapped =
        json.encode({"ok": false, "errorMessage": msg, "errors": errors});
    final srcResponse = _request!.innerRequest.response;
    srcResponse.headers.set(
        io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    srcResponse.statusCode = code;
    srcResponse.write(wrapped);
    _request!.cancel();
    return request;
  }

  // Response redirect(Object location, {bool permanent: true}) {
  //   _onlyOnce();
  //   _responseObject = ResponseObject.redirect(location, permanent);
  //   _response.cancel();
  //   return _response;
  // }

  int _getSuccessCode() {
    if (_request!.method == 'POST') {
      return io.HttpStatus.created;
    } else if (_request!.method == 'DELETE') {
      return io.HttpStatus.ok;
    } else {
      return io.HttpStatus.ok;
    }
  }

  // void _onlyOnce() {
  //   if (_responseObject != null) {
  //     throw ArrowException('The response object has already been created.');
  //   }
  // }

  // Future complete() async {
  //   if (ResponseObject == null) {
  //     throw ResponseObjectException('A response has not been created.');
  //   }
  //   final srcResponse = _response.request.innerRequest.response;
  //   if (_responseObject.body != null) {
  //     srcResponse.headers.set(
  //         io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
  //     srcResponse.statusCode = _responseObject.statusCode;
  //     srcResponse.write(_responseObject.body);
  //   } else if (_responseObject.location != null) {
  //     srcResponse.statusCode = _responseObject.statusCode;
  //     srcResponse.redirect(_responseObject.location);
  //   } else if (_responseObject.body == null) {
  //     srcResponse.statusCode = _responseObject.statusCode;
  //   } else {
  //     srcResponse.statusCode = io.HttpStatus.internalServerError;
  //   }
  //   await srcResponse.close();
  // }
}
