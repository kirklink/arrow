import 'dart:io';

import 'package:arrow/src/request.dart';
import 'package:arrow/src/request_middleware.dart';

/// Middleware that validates Content-Type headers by HTTP method.
///
/// - GET/DELETE must not have a Content-Type header.
/// - POST/PUT must have `application/json` Content-Type.
///
/// ```dart
/// router.onRequest(enforceJsonContentType());
/// ```
RequestMiddleware enforceJsonContentType() {
  return _enforceJsonContentType;
}

Future<Request> _enforceJsonContentType(Request req) async {
  ContentType? contentType = req.innerRequest.headers.contentType;
  if (req.method == 'GET' || req.method == 'DELETE') {
    if (contentType != null) {
      req.messenger
          .addError('Content type must be not be set on GET and DELETE.');
      req.respond.badRequest();
      return req;
    }
  }
  if (req.method == 'POST' || req.method == 'PUT') {
    if (contentType == null || contentType.mimeType != 'application/json') {
      req.messenger
          .addError('Content type must be application/json on POST and PUT.');
      req.respond.badRequest();
      return req;
    }
  }
  return req;
}
