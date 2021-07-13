import 'dart:async';
import 'package:uri/uri.dart' as u;

import 'endpoint.dart';
import 'request.dart';
import 'response.dart';
import 'response_middleware.dart';
import 'request_middleware.dart';
import 'guard.dart';
import 'handler.dart';
import 'middleware.dart';
import 'constants.dart' show RouterMethods;
import 'pipeline.dart';

class RouteBuilder {
  late String _pattern;
  late String _method;
  String get method => _method;
  late u.UriTemplate _template;
  late u.UriParser _parser;
  Endpoint _endpoint;
  Pipeline _pipeline;
  Guard? _guard;

  String get pattern => _pattern;

  RouteBuilder(String method, String pattern, Handler handler, {Guard? guard})
      : _endpoint = handler.endpoint,
        _pipeline = handler.pipeline,
        _guard = guard {
    if (RouterMethods.allowedMethods.indexOf(method) == -1) {
      throw ArgumentError('Method $method is not allowed in route $_pattern.');
    } else {
      _method = method;
    }
    if (!pattern.startsWith('/')) {
      _pattern = '/' + pattern;
    } else {
      _pattern = pattern;
    }
    _template = u.UriTemplate(_pattern);
    _parser = u.UriParser(_template, queryParamsAreOptional: true);
  }

  Future<bool> canHandle(Request req) async {
    print('methods');
    print(req.method);
    print(_method);
    print(req.method == _method);
    if (req.method != _method) return false;
    print('matches');
    print(_pattern);
    print(req.uri);
    var m = _parser.match(req.uri);
    print(m);
    return m != null && m.rest.hasEmptyPath;
  }

  void addOnRequest(RequestMiddleware requestMiddleware,
      {bool runAsync = false, bool useAlways = false}) {
    _pipeline = _pipeline.clone();
    _pipeline.onRequest(requestMiddleware,
        runAsync: runAsync, useAlways: useAlways);
  }

  void addOnResponse(ResponseMiddleware responseMiddleware,
      {bool runAsync = false, bool useAlways = false}) {
    _pipeline = _pipeline.clone();
    _pipeline.onResponse(responseMiddleware,
        runAsync: runAsync, useAlways: useAlways);
  }

  // void guard(Guard guard) {
  //   _pipeline = _pipeline.clone(guard);
  // }

  Future<Response> serve(Request req) async {
    req.params.load(_parser.parse(req.uri));
    return _pipeline.serve(req, _endpoint, guard: _guard);
  }
}
