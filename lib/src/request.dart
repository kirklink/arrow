import 'dart:io';
import 'package:uri/uri.dart' as u;

import 'package:arrow/src/message.dart';
import 'package:arrow/src/response.dart';
import 'package:arrow/src/parameters.dart';
import 'package:arrow/src/content.dart';

class Request extends Message {
  Parameters _params = Parameters();
  Content _content;

  Request(HttpRequest innerRequest) : super(innerRequest) {}

  // Convenience accessors.
  String get method => innerRequest.method;

  Uri get uri => u.UriBuilder.fromUri(innerRequest.uri).build();

  HttpHeaders get headers => innerRequest.headers;

  Parameters get params => _params;

  bool get isOnProd => Platform.environment['ARROW_ENVIRONMENT'] == 'production';

  // New functionality.
  Content get content => _content;

  set content(Content content) {
    if (_content != null) throw ContentException('Content is already loaded.');
    _content = content;
  }

  Response respond({String wrapper, bool wrapped}) {
    return Response(this, wrapper: wrapper, wrapped: wrapped);
  }

  void cancel() {
    manager.abort();
  }
}
