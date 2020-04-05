import 'dart:io';

import 'package:arrow/src/request.dart';

Request enforceJsonContentType(Request req) {
  ContentType contentType = req.innerRequest.headers.contentType;
  if (req.method == 'GET' || req.method == 'DELETE') {
    if (contentType != null) {
      req.messenger.addError('Content type must be not be set on GET and DELETE.');
      var res = req.response;
      res.send.badRequest();
      return req;
    }
    ;
  }
  if (req.method == 'POST' || req.method == 'PUT') {
    if (contentType == null || contentType.mimeType != 'application/json') {
      req.messenger.addError('Content type must be application/json on POST and PUT.');
      var res = req.response;
      res.send.badRequest();
      return req;
    }
  }
  return req;
}
