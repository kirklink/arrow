import 'dart:io';

import 'package:arrow/src/response.dart';
import 'package:arrow/src/manager.dart';

class Responder {

  Manager _manager;
  Response _response;
  
  Responder(this._response, this._manager, bool isWrapped, String wrapper) {
    _manager.setWrapper(isWrapped, wrapper);
  }

  int get statusCode => _manager.statusCode;

  Response ok(Map<String, Object> message) {
    _manager.setSuccess(message);
    return _response;
  }

  void success({int statusCode}) {
    _manager.setSuccess({}, statusCode: statusCode);
  }

  Response unauthorized() {
    _manager.setError(HttpStatus.unauthorized);
    return _response;
  }

  Response notFound() {
    _manager.setError(HttpStatus.notFound);
    return _response;
  }

  Response badRequest({Map<String, Object> errors}) {
    _manager.setError(HttpStatus.badRequest, errors: errors ?? {});
    return _response;
  }

  Response serverError() {
    _manager.setError(HttpStatus.internalServerError);
    return _response;
  }

  Response redirect(Uri location, {bool permanent:false}) {
    _manager.setRedirect(location, permanent);
    return _response;
  }

}
