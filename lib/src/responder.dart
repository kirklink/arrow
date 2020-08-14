import 'dart:io' as io;

import 'package:arrow/src/response.dart';
import 'package:arrow/src/response_object.dart';

class ResponderException implements Exception {
  String cause;
  ResponderException(this.cause);
}


class Responder {

  Response _response;
  ResponseObject _responseObject;
  
  Responder(this._response);

  bool get isComplete => _responseObject != null;
  int get statusCode => _responseObject.statusCode;

  Response ok([Map<String, Object> data]) {
    _onlyOnce();
    final code = _getSuccessCode();
    _responseObject = ResponseObject.ok(code, data);
    return _response;
  }

  Response raw(int statusCode, Map<String, Object> data) {
    _onlyOnce();
    _responseObject = ResponseObject.ok(statusCode, data, wrapped: false);
    return _response;
  }

  Response code(int statusCode) {
    _onlyOnce();
    _responseObject = ResponseObject.codeOnly(statusCode);
    return _response;
  }

  Response unauthorized() {
    _onlyOnce();
    _responseObject = ResponseObject.error(io.HttpStatus.unauthorized, 'Unauthorized', <String, String>{});
    _response.cancel();
    return _response;
  }

  Response notFound() {
    _onlyOnce();
    _responseObject = ResponseObject.error(io.HttpStatus.notFound, 'Not Found', <String, String>{});
    _response.cancel();
    return _response;
  }

  Response badRequest({String msg, Map<String, Object> errors}) {
    _onlyOnce();
    final m = msg ?? 'Bad Request';
    final e = errors ?? <String, String>{};
    _responseObject = ResponseObject.error(io.HttpStatus.badRequest, m, e);
    _response.cancel();
    return _response;
  }

  Response serverError() {
    _onlyOnce();
    _responseObject = ResponseObject.error(io.HttpStatus.internalServerError, 'Server Error', <String, String>{});
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
      srcResponse.headers.set(io.HttpHeaders.contentTypeHeader, 'application/json');
      srcResponse.write(_responseObject.body);
      srcResponse.statusCode = _responseObject.statusCode;
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
