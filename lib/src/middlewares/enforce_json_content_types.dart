import 'dart:io';

import 'package:arrow/src/request.dart';

Request enforceJsonContentType(Request req) {
  ContentType contentType = req.innerRequest.headers.contentType;
  if (req.method == 'GET' || req.method == 'DELETE') {
    if (contentType != null) {
      var res = req.respond();
      res.send.badRequest();
      return req;
    }
    ;
  }
  if (req.method == 'POST' || req.method == 'PUT') {
    if (contentType == null || contentType.mimeType != 'application/json') {
      var res = req.respond();
      res.send.badRequest();
      return req;
    }
  }
  return req;
}
