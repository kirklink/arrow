import 'dart:io' as io;

import 'package:arrow/src/response.dart';
import 'package:arrow/src/response_object.dart';

class ResponderException implements Exception {
  String cause;
  ResponderException(this.cause);

  @override
  String toString() => cause;
}

class Responder {
  Response _response;
  ResponseObject _responseObject;

  Responder(this._response);

  bool get isComplete => _responseObject != null;
  int get statusCode => _responseObject.statusCode;

  Response ok(
      {Object data = const <String, Object>{},
      String serializedData = '',
      bool printResponseObject = false}) {
    _onlyOnce();
    final code = _getSuccessCode();
    _responseObject = ResponseObject.ok(code, data);
    if (printResponseObject) {
      print(_responseObject);
    }
    return _response;
  }

  Response raw(int statusCode, Object data) {
    _onlyOnce();
    _responseObject = ResponseObject.ok(statusCode, data, wrapped: false);
    return _response;
  }

  Response code(int statusCode) {
    _onlyOnce();
    _responseObject = ResponseObject.codeOnly(statusCode);
    return _response;
  }

  Response unauthorized(
      {String msg = 'Unauthorized.',
      Map<String, Object> errors = const <String, String>{},
      bool printResponseObject = false}) {
    _onlyOnce();
    _responseObject =
        ResponseObject.error(io.HttpStatus.unauthorized, msg, errors);
    if (printResponseObject) {
      print(_responseObject);
    }
    _response.cancel();
    return _response;
  }

  Response notFound() {
    _onlyOnce();
    _responseObject = ResponseObject.error(
        io.HttpStatus.notFound, 'Not Found', const <String, String>{});
    _response.cancel();
    return _response;
  }

  Response badRequest(
      {String msg = 'Bad Request.',
      Map<String, Object> errors = const <String, String>{},
      bool printResponseObject = false}) {
    _onlyOnce();
    _responseObject =
        ResponseObject.error(io.HttpStatus.badRequest, msg, errors);
    if (printResponseObject) {
      print(_responseObject);
    }
    _response.cancel();
    return _response;
  }

  Response serverError() {
    _onlyOnce();
    _responseObject = ResponseObject.error(io.HttpStatus.internalServerError,
        'Server Error', const <String, String>{});
    _response.cancel();
    return _response;
  }

  Response redirect(Object location, {bool permanent: true}) {
    _onlyOnce();
    _responseObject = ResponseObject.redirect(location, permanent);
    _response.cancel();
    return _response;
  }

  int _getSuccessCode() {
    if (_response.innerRequest.method == 'POST') {
      return io.HttpStatus.created;
    } else if (_response.innerRequest.method == 'DELETE') {
      return io.HttpStatus.ok;
    } else {
      return io.HttpStatus.ok;
    }
  }

  void _onlyOnce() {
    if (_responseObject != null) {
      throw ResponderException('The response object has already been created.');
    }
  }

  Future complete() async {
    if (ResponseObject == null) {
      throw ResponseObjectException('A response has not been created.');
    }
    final srcResponse = _response.innerRequest.response;
    if (_responseObject.body != null) {
      srcResponse.headers.set(
          io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      srcResponse.statusCode = _responseObject.statusCode;
      srcResponse.write(_responseObject.body);
    } else if (_responseObject.location != null) {
      srcResponse.statusCode = _responseObject.statusCode;
      srcResponse.redirect(_responseObject.location);
    } else if (_responseObject.body == null) {
      srcResponse.statusCode = _responseObject.statusCode;
    } else {
      srcResponse.statusCode = io.HttpStatus.internalServerError;
    }
    await srcResponse.close();
  }
}
