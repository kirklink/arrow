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

  /// Whether a response has already been set on this responder.
  bool get isComplete => _complete;

  /// Send a 200 OK response with optional data.
  Response ok({Map<String, dynamic> data = const <String, dynamic>{}}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final encoded = json.encode({"ok": true, "data": data});
    final srcResponse = _request.innerRequest.response;
    srcResponse.headers.set(
        io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    srcResponse.statusCode = io.HttpStatus.ok;
    srcResponse.write(encoded);
    _complete = true;
    _response = Response(_request, data: data);
    return _response;
  }

  /// Send a 201 Created response with optional data.
  ///
  /// Use this for POST handlers that create new resources:
  ///
  /// ```dart
  /// return req.respond.created(data: {'id': newId, 'name': 'Alice'});
  /// ```
  Response created({Map<String, dynamic> data = const <String, dynamic>{}}) {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final encoded = json.encode({"ok": true, "data": data});
    final srcResponse = _request.innerRequest.response;
    srcResponse.headers.set(
        io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    srcResponse.statusCode = io.HttpStatus.created;
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
    _response = Response(_writeErrorAndCancel(_request, code, msg, errors));
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
    _response = Response(_writeErrorAndCancel(_request, code, msg, errors));
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
    _response = Response(_writeErrorAndCancel(_request, code, msg, errors));
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
    _response = Response(_writeErrorAndCancel(_request, code, msg, errors));
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
    _response = Response(_writeErrorAndCancel(_request, code, msg, errors));
    return _response;
  }

  Response serverError() {
    if (_complete) {
      throw ArrowException('The response has already been set.');
    }
    final code = io.HttpStatus.internalServerError;
    final msg = 'Server Error';
    _complete = true;
    _response = Response(_writeErrorAndCancel(_request, code, msg, const {}));
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
    _response = Response(_writeErrorAndCancel(_request, statusCode, msg, errors));
    return _response;
  }

  /// Set a cookie on the response. Returns this [Responder] for chaining.
  ///
  /// Cookies are serialized to Set-Cookie headers automatically by dart:io.
  /// Chain with a terminal response method for clean, readable code:
  ///
  /// ```dart
  /// return req.respond
  ///     .setCookie('session', 'abc123', httpOnly: true, secure: true)
  ///     .ok(data: {'loggedIn': true});
  /// ```
  Responder setCookie(
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
    return this;
  }

  /// Clear a cookie by setting it with an empty value and maxAge of 0.
  /// Returns this [Responder] for chaining.
  ///
  /// The [path] and [domain] must match the original cookie for the
  /// browser to recognize which cookie to delete.
  ///
  /// ```dart
  /// return req.respond.clearCookie('session', path: '/').ok(data: {'loggedOut': true});
  /// ```
  Responder clearCookie(String name, {String? path, String? domain}) {
    return setCookie(name, '', maxAge: Duration.zero, path: path, domain: domain);
  }

  Request _writeErrorAndCancel(
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
}
