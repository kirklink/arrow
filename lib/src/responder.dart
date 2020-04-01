import 'dart:io';


import 'package:arrow/src/manager.dart';

class Responder {

  Manager _manager;
  
  Responder(this._manager, bool isWrapped, String wrapper) {
    _manager.setWrapper(isWrapped, wrapper);
  }

  int get statusCode => _manager.statusCode;

  void ok(Map<String, Object> message) {
    _manager.setSuccess(message);
  }

  void success({int statusCode}) {
    _manager.setSuccess({}, statusCode: statusCode);
  }

  void unauthorized() {
    _manager.setError(HttpStatus.unauthorized);
  }

  void notFound() {
    _manager.setError(HttpStatus.notFound);
  }

  void badRequest({Map<String, Object> errors}) {
    _manager.setError(HttpStatus.badRequest, errors: errors ?? {});
  }

  void serverError() {
    _manager.setError(HttpStatus.internalServerError);
  }

  void redirect(Uri location, {bool permanent:false}) {
    _manager.setRedirect(location, permanent);
  }

}
