import 'dart:io';
import 'package:recase/recase.dart' as recase;

import 'package:arrow/src/request.dart';
import 'package:arrow/src/request_middleware.dart';

class Cors {
  final _defaultHeaders = const [
    'Origin',
    'Accept',
    'Content-Type',
    'Authorization'
  ];
  final _defaultMethods = const ['GET', 'POST', 'PUT', 'DELETE'];
  bool _allowAllOrigins = false;
  bool _allowAllHeaders = false;
  bool _allowAllMethods = false;
  List<String> _allowedHeaders = [];
  List<String> _allowedMethods = [];
  List<List<String>> _allowedOrigins = [];
  final int maxAge;
  final bool allowCredentials;
  final List<String> exposedHeaders;

  Cors(
      {List<String> allowedOrigins,
      List<String> allowedHeaders,
      List<String> allowedMethods,
      this.maxAge = 0,
      this.allowCredentials = false,
      this.exposedHeaders = const []}) {
    if (allowedHeaders != null) {
      if (allowedHeaders.contains('*')) {
        _allowAllHeaders = true;
      } else {
        _allowedHeaders =
            allowedHeaders.map((e) => recase.ReCase(e).headerCase).toList();
      }
    } else {
      _allowedHeaders = _defaultHeaders;
    }

    if (allowedMethods != null) {
      if (allowedMethods.contains('*')) {
        _allowAllMethods = true;
      } else {
        _allowedMethods = allowedMethods.map((e) => e.toUpperCase()).toList();
      }
    } else {
      _allowedMethods = _defaultMethods;
    }

    if (allowedOrigins != null) {
      if (allowedOrigins.any((e) => e == '*')) {
        _allowAllOrigins = true;
      } else {
        _allowedOrigins = allowedOrigins.map((e) {
          final split = e.split('*');
          if (split.length > 2) {
            throw ArgumentError(
                '[cors] Invalid wildcard origin provided: ${e}');
          }
          if (split.length < 2) {
            split.add('');
          }
          return [split[0].toLowerCase(), split[1].toLowerCase()];
        }).toList();
      }
    } else {
      _allowAllOrigins = true;
    }
  }

  bool isAllowedOrigin(String origin) {
    if (_allowAllOrigins) {
      return true;
    } else {
      return _allowedOrigins
          .any((e) => origin.startsWith(e[0]) && origin.endsWith(e[1]));
    }
  }

  bool isAllowedMethod(String method) {
    if (_allowAllMethods) {
      return true;
    }
    method = method.toUpperCase();
    if (method == 'OPTIONS') {
      return true;
    }
    return _allowedMethods.contains(method);
  }

  bool areAllowedHeaders(List<String> headers) {
    if (headers.length == 0) {
      return true;
    }
    if (_allowAllHeaders) {
      return true;
    }
    return headers.every((e) => _allowedHeaders.contains(e));
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

  req.innerRequest.response.headers
      .add(HttpHeaders.varyHeader, 'Access-Control-Request-Method');
  req.innerRequest.response.headers
      .add(HttpHeaders.varyHeader, 'Access-Control-Request-Headers');

  final origin = Uri.tryParse(req.headers.value('Origin') ?? '');

  if (origin == null || !origin.hasScheme || !origin.hasAuthority) {
    req.response.messenger.addError(
        ('[cors] Preflight aborted. Could not determine the origin.'));
  }

  req.innerRequest.response.headers.add(HttpHeaders.varyHeader, 'Origin');

  if (!cors.isAllowedOrigin(origin.origin)) {
    var res = req.response;
    res.messenger.addError('[cors] Preflight aborted. Not an allowed origin.');
    res.send.badRequest();
    return req;
  }

  final method = req.headers.value('Access-Control-Request-Method') ?? '';
  if (method.isEmpty || !cors.isAllowedMethod(method)) {
    var res = req.response;
    res.messenger.addError('[cors] Preflight aborted. Not an allowed method.');
    res.send.badRequest();
    return req;
  }

  final headers = req.headers.value('Access-Control-Request-Headers') ?? '';
  final split = headers.split(',');
  final parsedHeaders =
      split.map((e) => recase.ReCase(e.trim()).headerCase).toList();

  if (parsedHeaders.length == 0 || !cors.areAllowedHeaders(parsedHeaders)) {
    var res = req.response;
    res.messenger.addError('[cors] Preflight aborted. Not an allowed header.');
    res.send.badRequest();
    return req;
  }

  req.innerRequest.response.headers
      .add('Access-Control-Allow-Origin', origin.origin);
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

  final origin = Uri.tryParse(req.headers.value('Origin') ?? '');

  if (origin == null || !origin.hasScheme || !origin.hasAuthority) {
    req.response.messenger.addError(
        ('[cors] Preflight aborted. Could not determine the origin.'));
  }

  if (origin == null || origin == '') {
    var res = req.response;
    res.messenger.addError('[cors] Actual request aborted. Empty origin.');
    res.send.badRequest();
    return req;
  }

  if (!cors.isAllowedOrigin(origin.origin)) {
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
  return (Request req) async {
    if (req.method == 'OPTIONS') {
      return handlePreFlight(req, config);
    } else {
      return handleActualRequest(req, config);
    }
  };
}
