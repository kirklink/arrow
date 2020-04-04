import 'dart:io' as io;

class ResponseObjectException implements Exception {
  String cause;

  ResponseObjectException(this.cause);
}


abstract class ResponseObject {

  int _statusCode;
  bool _ok;
  Map<String, Object> _data;
  String _errorMsg;
  Map<String, String> _errors;
  io.ContentType _contentType;
  Uri _uri;


  ResponseObject._ok(this._statusCode, this._data) {
    _ok = _statusCode >= 200 || _statusCode <= 299;
    if (!_ok) {
      throw ResponseObjectException('Response cannot be "ok" with status code $_statusCode.');
    }
  }
  ResponseObject._error(this._statusCode, this._errorMsg, this._errors) {
    _ok = _statusCode < 200 || _statusCode >= 400;
    if (_ok) {
      throw ResponseObjectException('Response must be "ok" with status code $_statusCode.');
    }
  }
  ResponseObject._redirect(bool permanent, Object uri) {
    if (uri is String) {
      _uri = Uri.parse(uri);
    } else if (uri is Uri) {
      _uri = uri;
    } else {
      throw ResponseObjectException('uri must be a string or uri object.');
    }
    _ok = true;
    if (permanent) {
      _statusCode = 301;
    } else {
      _statusCode = 302;
    }
  }
  ResponseObject._codeOnly(this._statusCode);

  
  


}


class ArrowResponse extends ResponseObject {
  
  io.ContentType _contentType = io.ContentType.json;

  ArrowResponse.ok(int statusCode, Map<String, Object> data)
     : super._ok(statusCode, data);
  ArrowResponse.error(int statusCode, String msg, Map<String, Object> errors)
     : super._error(statusCode, msg, errors);
  ArrowResponse.redirect(bool permanent, Object uri)
     : super._redirect(permanent, uri);
  ArrowResponse.codeOnly(int statusCode) : super._codeOnly(statusCode);
  

}


