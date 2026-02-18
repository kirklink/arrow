import 'dart:io' as io;
import 'dart:convert' show json;

import 'response.dart';
import 'request.dart';
import 'arrow_exception.dart';
import 'mime_type.dart';

class Responder {
  final Request _request;
  var _complete = false;
  late final Response _response;

  Responder(this._request);

  Response get response => _response;

  Response ok(
      {Map<String, dynamic> data = const <String, dynamic>{},
      bool printResponseObject = false}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = _getSuccessCode();
    final encoded = json.encode({"ok": true, "data": data});
    final srcResponse = _request.innerRequest.response;
    srcResponse.headers.set(
        io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    srcResponse.statusCode = code;
    srcResponse.write(encoded);
    _complete = true;
    _response = Response(_request, data: data);
    return _response;
  }

  Response raw(int statusCode, Map<String, dynamic> data) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final encoded = json.encode(data);
    final srcResponse = _request.innerRequest.response;
    srcResponse.headers.set(
        io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    srcResponse.statusCode = statusCode;
    srcResponse.write(encoded);
    _complete = true;
    _response = Response(_request, data: data);
    return _response;
  }

  Response code(int statusCode) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final srcResponse = _request.innerRequest.response;
    srcResponse.statusCode = statusCode;
    _complete = true;
    _response = Response(_request);
    return _response;
  }

  /// Serve a file with appropriate Content-Type and caching headers.
  ///
  /// Unlike other Responder methods, this is `async` because it streams
  /// the file contents to the response. The response is finalized after
  /// streaming completes.
  ///
  /// ```dart
  /// final file = File('uploads/photo.png');
  /// return await req.respond.sendFile(file);
  /// ```
  Future<Response> sendFile(io.File file,
      {String? contentType, int statusCode = 200}) async {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final stat = await file.stat();
    final srcResponse = _request.innerRequest.response;
    srcResponse.statusCode = statusCode;
    srcResponse.headers.set(io.HttpHeaders.contentTypeHeader,
        contentType ?? MimeType.fromPath(file.path).value);
    srcResponse.headers.set(io.HttpHeaders.contentLengthHeader, stat.size);
    await srcResponse.addStream(file.openRead());
    _complete = true;
    _request.cancel();
    _response = Response(_request);
    return _response;
  }

  Response unauthorized(
      {String msg = 'Unauthorized',
      Map<String, Object> errors = const <String, Object>{}}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.unauthorized;
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, errors));
    return _response;
  }

  Response notFound(
      {String msg = 'Not Found',
      Map<String, Object> errors = const <String, Object>{}}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.notFound;
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, errors));
    return _response;
  }

  Response forbidden(
      {String msg = 'Forbidden',
      Map<String, Object> errors = const <String, Object>{}}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.forbidden;
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, errors));
    return _response;
  }

  Response badRequest(
      {String msg = 'Bad Request',
      Map<String, Object> errors = const <String, Object>{}}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.badRequest;
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, errors));
    return _response;
  }

  /// 429 Too Many Requests — rate limit exceeded.
  Response tooManyRequests(
      {String msg = 'Too Many Requests',
      Map<String, Object> errors = const <String, Object>{}}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = 429;
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, errors));
    return _response;
  }

  Response serverError() {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.internalServerError;
    final msg = 'Server Error';
    _complete = true;
    _response = Response(_errorResponse(_request, code, msg, const {}));
    return _response;
  }

  /// Send a generic error response with a custom status code.
  ///
  /// ```dart
  /// req.respond.error(429, msg: 'Too Many Requests');
  /// ```
  Response error(int statusCode,
      {String msg = 'Error',
      Map<String, Object> errors = const <String, Object>{}}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    _complete = true;
    _response = Response(_errorResponse(_request, statusCode, msg, errors));
    return _response;
  }

  /// Set a cookie on the response.
  ///
  /// Must be called before any terminal response method ([ok], [badRequest],
  /// etc.) since those finalize the response. Cookies are serialized to
  /// Set-Cookie headers automatically by dart:io.
  ///
  /// ```dart
  /// req.respond.setCookie('session', 'abc123',
  ///   httpOnly: true,
  ///   secure: true,
  ///   maxAge: Duration(hours: 24),
  ///   path: '/',
  ///   sameSite: SameSite.strict,
  /// );
  /// return req.respond.ok(data: {'loggedIn': true});
  /// ```
  void setCookie(
    String name,
    String value, {
    Duration? maxAge,
    DateTime? expires,
    String? path,
    String? domain,
    bool httpOnly = true,
    bool secure = false,
    io.SameSite? sameSite,
  }) {
    if (_complete) {
      throw ArrowException('Cannot set cookie after response has been sent.');
    }
    final cookie = io.Cookie(name, value);
    if (maxAge != null) cookie.maxAge = maxAge.inSeconds;
    if (expires != null) cookie.expires = expires;
    if (path != null) cookie.path = path;
    if (domain != null) cookie.domain = domain;
    cookie.httpOnly = httpOnly;
    cookie.secure = secure;
    if (sameSite != null) cookie.sameSite = sameSite;
    _request.innerRequest.response.cookies.add(cookie);
  }

  /// Clear a cookie by setting it with an empty value and maxAge of 0.
  ///
  /// The [path] and [domain] must match the original cookie for the
  /// browser to recognize which cookie to delete.
  ///
  /// ```dart
  /// req.respond.clearCookie('session', path: '/');
  /// return req.respond.ok(data: {'loggedOut': true});
  /// ```
  void clearCookie(String name, {String? path, String? domain}) {
    setCookie(name, '', maxAge: Duration.zero, path: path, domain: domain);
  }

  Request _errorResponse(
      Request request, int code, String msg, Map<String, Object> errors) {
    final wrapped =
        json.encode({"ok": false, "errorMessage": msg, "errors": errors});
    final srcResponse = _request.innerRequest.response;
    srcResponse.headers.set(
        io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    srcResponse.statusCode = code;
    srcResponse.write(wrapped);
    _request.cancel();
    return request;
  }

  // Response redirect(Object location, {bool permanent: true}) {
  //   _onlyOnce();
  //   _responseObject = ResponseObject.redirect(location, permanent);
  //   _response.cancel();
  //   return _response;
  // }

  int _getSuccessCode() {
    if (_request.method == 'POST') {
      return io.HttpStatus.created;
    } else if (_request.method == 'DELETE') {
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
