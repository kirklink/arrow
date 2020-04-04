import 'dart:io';

import 'package:arrow/src/response.dart';
import 'package:arrow/src/manager.dart';
import 'package:arrow/src/response_object.dart';

// TODO: provide some more flexibility in responses
// TODO: create a response object (between here and manager) to standardize output`

class Responder {

  Response _response;
  ResponseObject _responseObject;
  
  Responder(this._response);

  Response ok(Map<String, Object> data) {
    _responseObject = ArrowResponse.ok(200, data);
    return _response;
  }

  Response code(int statusCode) {
    _responseObject = ArrowResponse.codeOnly(statusCode);
    return _response;
  }

  Response unauthorized() {
    _responseObject = ArrowResponse.error(HttpStatus.unauthorized, 'Unauthorized', {});
    return _response;
  }

  Response notFound() {
    _responseObject = ArrowResponse.error(HttpStatus.notFound, 'Not Found', {});
    return _response;
  }

  Response badRequest({String msg, Map<String, Object> errors}) {
    final m = msg ?? 'Bad Request';
    final e = errors ?? {};
    _responseObject = ArrowResponse.error(HttpStatus.badRequest, m, e);
    return _response;
  }

  Response serverError() {
    _responseObject = ArrowResponse.error(HttpStatus.internalServerError, 'Server Error', {});
    return _response;
  }

  Response redirect(Object location, {bool permanent: true}) {
    _responseObject = ArrowResponse.redirect(location, permanent);
    return _response;
  }

}
