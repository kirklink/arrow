import 'dart:convert' show json;

class ResponseObjectException implements Exception {
  String cause;

  ResponseObjectException(this.cause);
  @override
  String toString() => cause;
}

class ResponseObject {
  int _statusCode;
  String _body;
  Uri _uri;

  int get statusCode => _statusCode;
  String get body => _body;
  Uri get location => _uri;

  @override
  String toString() {
    return {'statusCode': _statusCode, 'body': json.decode(_body)}.toString();
  }

  ResponseObject.ok(this._statusCode, Object data, {bool wrapped = true}) {
    if (data is! Map<String, Object> && data is! String) {
      throw ResponseObjectException(
          'data provided must be a serialized string or a Map<String, Object>');
    }
    if (_statusCode < 200 || _statusCode > 299) {
      throw ResponseObjectException(
          'Response cannot be "ok" with status code $_statusCode.');
    }
    if (data is String) {
      data = json.decode(data);
    }
    if (wrapped) {
      _body = json.encode({"ok": true, "data": data});
    } else {
      _body = json.encode(data);
    }
  }

  ResponseObject.error(
      this._statusCode, String errorMsg, Map<String, String> errors) {
    if (_statusCode > 200 && _statusCode < 400) {
      throw ResponseObjectException(
          'Response must be "ok" with status code $_statusCode.');
    }
    _body =
        json.encode({"ok": false, "errorMessage": errorMsg, "errors": errors});
  }

  ResponseObject.redirect(bool permanent, Object uri) {
    if (uri is String) {
      try {
        _uri = Uri.parse(uri);
      } catch (e) {
        throw ResponseObjectException('Could not parse uri: $uri.');
      }
    } else if (uri is Uri) {
      _uri = uri;
    } else {
      throw ResponseObjectException('uri must be a string or Uri object.');
    }
    if (permanent) {
      _statusCode = 301;
    } else {
      _statusCode = 302;
    }
  }

  ResponseObject.codeOnly(this._statusCode);
}
