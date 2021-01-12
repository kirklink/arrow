import 'dart:io';

import 'package:recase/recase.dart' as recase;

import 'package:arrow/src/request.dart';
import 'package:arrow/src/request_middleware.dart';

class Cors {
  List<String> _allowedOrigins = ['*'];
  List<String> _allowedHeaders = [
    'Origin',
    'Accept',
    'Content-Type',
    'Authorization'
  ];
  List<String> _allowedMethods = ['GET', 'POST', 'PUT', 'DELETE'];
  List<List<String>> _allowedWildcardOrigins;
  bool _allowAllOrigins = false;
  bool _allowAllHeaders = false;
  bool _allowAllMethods = false;
  final int maxAge;
  final bool allowCredentials;
  final List<String> exposedHeaders;

  Cors(
      {List<String> allowedOrigins,
      List<String> allowedHeaders,
      List<String> allowedMethods,
      this.maxAge,
      this.allowCredentials: false,
      this.exposedHeaders}) {
    if (allowedHeaders != null) {
      if (allowedHeaders.isEmpty) {
        _allowedHeaders = List(0);
      } else {
        _allowedHeaders = List.from(allowedHeaders, growable: false);
        for (int i = 0; i < _allowedHeaders.length; i++) {
          _allowedHeaders[i] = recase.ReCase(_allowedHeaders[i]).headerCase;
          if (_allowedHeaders[i] == '*') {
            _allowedHeaders = null;
            _allowAllHeaders = true;
            break;
          }
        }
        ;
      }
    }

    const origin = 'Origin';
    if (!_allowAllHeaders &&
        _allowedHeaders != null &&
        !_allowedHeaders.contains(origin)) {
      _allowedHeaders.add(origin);
    }

    if (allowedMethods != null) {
      if (allowedMethods.isEmpty) {
        _allowedMethods = List(0);
      } else {
        _allowedMethods = List.from(allowedMethods, growable: false);
        for (int i = 0; i < _allowedMethods.length; i++) {
          _allowedMethods[i].toUpperCase();
          if (_allowedMethods[i] == '*') {
            _allowedMethods = null;
            _allowAllMethods = true;
            break;
          }
        }
      }
    }

    if (allowedOrigins != null) {
      _allowedOrigins = null;
      if (allowedOrigins.isEmpty) {
        _allowedOrigins = List(0);
      } else {
        for (int i = 0; i < allowedOrigins.length; i++) {
          final current = allowedOrigins[i];
          if (current == '*') {
            _allowedOrigins = null;
            _allowAllOrigins = true;
            break;
          } else if (current.contains('*')) {
            if (_allowedWildcardOrigins == null)
              _allowedWildcardOrigins = List<List<String>>();
            var split = current.split('*');
            if (split.length != 2) {
              throw ArgumentError(
                  '[cors] Invalid wildcard origin provided: ${current}');
            }
            split.map((o) => o.toLowerCase());
            _allowedWildcardOrigins.add(List.from(split, growable: false));
          } else {
            if (_allowedOrigins == null) _allowedOrigins = List<String>();
            _allowedOrigins.add(current.toLowerCase());
          }
        }
      }
    }
  }

  bool isAllowedOrigin(String origin) {
    if (_allowAllOrigins) return true;
    if (_allowedOrigins != null) {
      for (int i = 0; i < _allowedOrigins.length; i++) {
        if (origin == _allowedOrigins[i].toLowerCase()) {
          return true;
        }
      }
    }
    if (_allowedWildcardOrigins != null) {
      for (int i = 0; i < _allowedWildcardOrigins.length; i++) {
        var o = _allowedWildcardOrigins[i];
        if (origin.startsWith(o[0]) && origin.endsWith(o[1])) {
          return true;
        }
      }
    }
    return false;
  }

  bool isAllowedMethod(String method) {
    if (_allowAllMethods) return true;
    method = method.toUpperCase();
    if (method == 'OPTIONS') return true;
    for (var allowedMethod in _allowedMethods) {
      if (method == allowedMethod) {
        return true;
      }
    }
    return false;
  }

  bool areAllowedHeaders(List<String> headers) {
    if (headers.length == 0) return true;
    if (_allowAllHeaders) return true;
    bool areAllowed = true;
    for (var header in headers) {
      if (_allowedHeaders.contains(header)) {
        areAllowed = true;
      } else {
        areAllowed = false;
        break;
      }
    }
    return areAllowed;
  }
}

Request handlePreFlight(Request req, Cors cors) {
  if (req.method != 'OPTIONS') {
    var res = req.response;
    res.messenger
        .addError(('[cors] Preflight aborted. ${req.method}!="OPTIONS'));
    res.send.serverError();
    return req;
  }

  req.innerRequest.response.headers.add(HttpHeaders.varyHeader, 'Origin');
  req.innerRequest.response.headers
      .add(HttpHeaders.varyHeader, 'Access-Control-Request-Method');
  req.innerRequest.response.headers
      .add(HttpHeaders.varyHeader, 'Access-Control-Request-Headers');

  final origin = req.headers.value('Origin');
  if (origin == null || origin == '') {
    var res = req.response;
    res.messenger.addError('[cors] Preflight aborted. Empty origin.');
    res.send.badRequest();
    return req;
  }

  if (!cors.isAllowedOrigin(origin)) {
    var res = req.response;
    res.messenger.addError('[cors] Preflight aborted. Not an allowed origin.');
    res.send.badRequest();
    return req;
  }

  final method = req.headers.value('Access-Control-Request-Method');
  if (method == null || !cors.isAllowedMethod(method)) {
    var res = req.response;
    res.messenger.addError('[cors] Preflight aborted. Not an allowed method.');
    res.send.badRequest();
    return req;
  }

  final headers = req.headers.value('Access-Control-Request-Headers');
  List<String> parsedHeaders = List<String>();
  if (headers != null && headers != '') {
    List<String> split = headers.split(',');
    for (int i = 0; i < split.length; i++) {
      parsedHeaders.add(recase.ReCase(split[i].trim()).headerCase);
    }
  }

  if (parsedHeaders.length == 0 || !cors.areAllowedHeaders(parsedHeaders)) {
    var res = req.response;
    res.messenger.addError('[cors] Preflight aborted. Not an allowed header.');
    res.send.badRequest();
    return req;
  }

  req.innerRequest.response.headers.add('Access-Control-Allow-Origin', origin);
  req.innerRequest.response.headers
      .add('Access-Control-Allow-Methods', method.toUpperCase());
  if (parsedHeaders.length > 0) {
    req.innerRequest.response.headers
        .add('Access-Control-Allow-Headers', parsedHeaders.join(', '));
  }

  if (cors.allowCredentials != null && cors.allowCredentials) {
    req.innerRequest.response.headers
        .add('Access-Control-Allow-Credentials', 'true');
  }

  if (cors.maxAge != null && cors.maxAge > 0) {
    req.innerRequest.response.headers
        .add('Access-Control-Max-Age', cors.maxAge.toString());
  }

  req.response.send.code(200);
  req.cancel();
  return req;
}

Request handleActualRequest(Request req, Cors cors) {
  req.innerRequest.response.headers.add(HttpHeaders.varyHeader, 'Origin');

  final origin = req.headers.value('Origin');

  if (origin == null || origin == '') {
    var res = req.response;
    res.messenger.addError('[cors] Actual request aborted. Empty origin.');
    res.send.badRequest();
    return req;
  }

  if (!cors.isAllowedOrigin(origin)) {
    var res = req.response;
    res.messenger.addError(
        '[cors] Actual request aborted. Not an allowed origin: $origin');
    res.send.badRequest();
    return req;
  }

  if (!cors.isAllowedMethod(req.method)) {
    var res = req.response;
    res.messenger.addError(
        '[cors] Actual request aborted. Not an allowed method: ${req.method}');
    res.send.badRequest();
    return req;
  }

  req.innerRequest.response.headers.add('Access-Control-Allow-Origin', origin);

  if (cors.allowCredentials != null && cors.allowCredentials) {
    req.innerRequest.response.headers
        .add('Access-Control-Allow-Credentials', 'true');
  }

  if (cors.exposedHeaders != null && cors.exposedHeaders.length > 0) {
    req.innerRequest.response.headers
        .add('Access-Control-Expose-Headers', cors.exposedHeaders.join(', '));
  }

  return req;
}

RequestMiddleware CorsMiddleware(Cors config) {
  return (Request req) {
    if (req.method == 'OPTIONS') {
      return handlePreFlight(req, config);
    } else {
      return handleActualRequest(req, config);
    }
  };
}
