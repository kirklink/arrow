import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8, json;
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

  // New functionality.
  Content get content => _content;

  set content(Content content) {
    if (_content != null) throw ContentException('Content is already loaded.');
    _content = content;
  }

  Response respond({String wrapper, bool wrapped}) {
    return Response(this, wrapper: wrapper, wrapped: wrapped);
  }

  Future<Response> forward(Uri uri, {String jwt}) async {
    var req = http.Request(innerRequest.method, uri);
    req.body = _content.encode();
    req.headers.putIfAbsent('Content-Type', () => 'application/json');
    if (jwt != null) req.headers.putIfAbsent(
        'Authorization', () => 'Bearer $jwt');
    http.StreamedResponse next = await req.send();
    var body = await next.stream.bytesToString();
    var res = this.respond(wrapped: false);
    res.send.relayJson(body, next.statusCode);
    return res;
  }

  void cancel() {
    manager.abort();
  }
}
