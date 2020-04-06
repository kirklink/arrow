import 'dart:io' as io;
import 'dart:convert' show json;

class ResponseObjectException implements Exception {
  String cause;

  ResponseObjectException(this.cause);
}

// class ResponseObjectResult {
//   final String body;
//   final int statusCode;
//   final io.ContentType contentType;
//   Uri _location;

//   Uri get location => _location;

//   ResponseObjectResult(this.body, this.statusCode, this.contentType, {Uri location}) {
//     _location = location;
//   }
// }


class ResponseObject {

  int _statusCode;
  String _body;
  Uri _uri;

  int get statusCode => _statusCode;
  String get body => _body;
  Uri get location => _uri;


  ResponseObject.ok(this._statusCode, Map<String, Object> data) {
    if (_statusCode < 200 || _statusCode > 299) {
      throw ResponseObjectException('Response cannot be "ok" with status code $_statusCode.');
    }
    _body = json.encode({
      "ok": true,
      "data": data
    });
  }
  
  ResponseObject.error(this._statusCode, String errorMsg, Map<String, String> errors) {
    if (_statusCode > 200 && _statusCode < 400) {
      throw ResponseObjectException('Response must be "ok" with status code $_statusCode.');
    }
    _body = json.encode({
      "ok": false,
      "errorMessage": errorMsg,
      "errors": errors
    });
  }
  
  ResponseObject.redirect(bool permanent, Object uri) {
    if (uri is String) {
      _uri = Uri.parse(uri);
    } else if (uri is Uri) {
      _uri = uri;
    } else {
      throw ResponseObjectException('uri must be a string or uri object.');
    }
    if (permanent) {
      _statusCode = 301;
    } else {
      _statusCode = 302;
    }
  }
  
  
  ResponseObject.codeOnly(this._statusCode);


}




