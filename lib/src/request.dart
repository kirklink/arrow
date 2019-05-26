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

  Future<Response> forward() async {
    Uri uri = Uri.parse('http://localhost:8999/echo-2');
    var req = http.Request('POST', uri);
    req.body = _content.encode();
    print('sending');
    print(uri);
    http.StreamedResponse next = await req.send();
    print('got');
    var body = await next.stream.bytesToString();
    print('body');
    print(next.statusCode);
//    var res = this.respond();
//    res.send.render(next)
//    req.body =_content.encode();
//    headers.forEach((s, l) {
//      print(s);
//      req.headers[s] = l.toString();
//    });

    var res = this.respond();
    res.send.render(body);
    return res;
  }

  void cancel() {
    manager.abort();
  }
}
