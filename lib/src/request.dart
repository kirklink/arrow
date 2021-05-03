import 'dart:io';
import 'package:uri/uri.dart' as u;

import 'arrow_exception.dart';
import 'responder.dart';
import 'parameters.dart';
import 'content.dart';
import 'context.dart';
import 'internal_messenger.dart';

class Request {
  Content _content;
  final HttpRequest innerRequest;
  final context = Context();
  final messenger = InternalMessenger();
  final params = Parameters();
  bool _isAlive = true;
  Responder _responder = Responder();

  Request(this.innerRequest);

  bool get isAlive => _isAlive;
  void cancel() => _isAlive = false;
  Content get content => _content;

  // Convenience accessors.
  String get method => innerRequest.method;
  Uri get uri => u.UriBuilder.fromUri(innerRequest.uri).build();
  HttpHeaders get headers => innerRequest.headers;

  set content(Content content) {
    if (_content != null) throw ArrowException('Content is already loaded.');
    _content = content;
  }

  Responder get respond => _responder.go(this);
}
