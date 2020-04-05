import 'dart:io';
import 'package:uri/uri.dart' as u;

import 'package:arrow/src/message.dart';
import 'package:arrow/src/response.dart';
import 'package:arrow/src/parameters.dart';
import 'package:arrow/src/content.dart';

class Request extends Message {
  Parameters _params = Parameters();
  Content _content;
  Response _response;

  Request(HttpRequest innerRequest) : super(innerRequest);

  // Convenience accessors.
  String get method => innerRequest.method;

  Uri get uri => u.UriBuilder.fromUri(innerRequest.uri).build();

  HttpHeaders get headers => innerRequest.headers;

  Parameters get params => _params;

  // New functionality.
  Content get content => _content;

  // Alive get alive => _alive;

  set content(Content content) {
    if (_content != null) throw ContentException('Content is already loaded.');
    _content = content;
  }

  Response get response {
    if (_response == null) {
      _response = Response(this);
      return _response;
    } else {
      return _response;
    }
  }


}
