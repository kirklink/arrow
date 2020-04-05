import 'dart:io' as io;

import 'package:arrow/src/response.dart';
import 'package:arrow/src/response_object.dart';

// TODO: provide some more flexibility in responses
// TODO: create a response object (between here and manager) to standardize output`

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
    if (_responseObject != null) {
      throw ResponderException('The response object has already been created.');
    }
    final code = _getSuccessCode();
    _responseObject = ResponseObject.ok(code, data);
    return _response;
  }

  Response code(int statusCode) {
    if (_responseObject != null) {
      throw ResponderException('The response object has already been created.');
    }
    _responseObject = ResponseObject.codeOnly(statusCode);
    return _response;
  }

  Response unauthorized() {
    if (_responseObject != null) {
      throw ResponderException('The response object has already been created.');
    }
    _responseObject = ResponseObject.error(io.HttpStatus.unauthorized, 'Unauthorized', <String, String>{});
    _response.cancel();
    return _response;
  }

  Response notFound() {
    if (_responseObject != null) {
      throw ResponderException('The response object has already been created.');
    }
    _responseObject = ResponseObject.error(io.HttpStatus.notFound, 'Not Found', <String, String>{});
    _response.cancel();
    return _response;
  }

  Response badRequest({String msg, Map<String, Object> errors}) {
    if (_responseObject != null) {
      throw ResponderException('The response object has already been created.');
    }
    final m = msg ?? 'Bad Request';
    final e = errors ?? <String, String>{};
    _responseObject = ResponseObject.error(io.HttpStatus.badRequest, m, e);
    _response.cancel();
    return _response;
  }

  Response serverError() {
    if (_responseObject != null) {
      throw ResponderException('The response object has already been created.');
    }
    _responseObject = ResponseObject.error(io.HttpStatus.internalServerError, 'Server Error', <String, String>{});
    _response.cancel();
    return _response;
  }

  Response redirect(Object location, {bool permanent: true}) {
    if (_responseObject != null) {
      throw ResponderException('The response object has already been created.');
    }
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

  Future complete() async {
    if (ResponseObject == null) {
      throw ResponseObjectException('A response has not been created.');
    }
    _response.innerRequest.response.headers.set(io.HttpHeaders.contentTypeHeader, 'application/json');
    _response.innerRequest.response.statusCode = _responseObject.statusCode;
    if (_responseObject.location != null) {
      _response.innerRequest.response.redirect(_responseObject.location);
    } else if (_responseObject.body != null) {
      _response.innerRequest.response.write(_responseObject.body);
    }
    await _response.innerRequest.response.close();
  }

}
