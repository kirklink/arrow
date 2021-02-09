import 'dart:async';
import 'package:uri/uri.dart' as u;

import 'handler.dart';
import 'request.dart';
import 'response.dart';
import 'response_middleware.dart';
import 'request_middleware.dart';
import 'guard.dart';
import 'middleware.dart';
import 'constants.dart' show RouterMethods;
import 'pipeline.dart';

class Route {
  String _pattern;
  String _method;
  u.UriTemplate _template;
  u.UriParser _parser;
  Handler _endpoint;
  Pipeline _pipeline;

  String get pattern => _pattern;

  Route(String method, this._pattern, Handler this._endpoint,
      Pipeline this._pipeline) {
    if (RouterMethods.allowedMethods.indexOf(method) == -1) {
      throw ArgumentError('Method $method is not allowed in route $_pattern.');
    } else {
      _method = method;
    }
    _template = u.UriTemplate(_pattern);
    _parser = u.UriParser(_template, queryParamsAreOptional: true);
  }

  bool canHandle(String method, Uri uri) {
    if (method != _method) return false;
    var m = _parser.match(uri);
    return m != null && m.rest.hasEmptyPath;
  }

  void addSync(
      {RequestMiddleware pre,
      ResponseMiddleware post,
      Handler error,
      bool useAlways: false}) {
    _pipeline = _pipeline.clone();
    _pipeline.use(Middleware(
        onRequest: pre, onResponse: post, error: error, useAlways: useAlways));
  }

  void addAsync(
      {RequestMiddleware pre,
      ResponseMiddleware post,
      Handler error,
      bool useAlways: false}) {
    _pipeline = _pipeline.clone();
    _pipeline.use(Middleware(
        onRequest: pre,
        onResponse: post,
        error: error,
        runAsync: true,
        useAlways: useAlways));
  }

  void add(Middleware middleware) {
    _pipeline = _pipeline.clone();
    _pipeline.use(middleware);
  }

  void guard(Guard guard) {
    _pipeline = _pipeline.clone(GuardBuilder(guard));
  }

  Future<Response> serve(Request req) async {
    req.params.load(_parser.parse(req.uri));
    return _pipeline.serve(req, _endpoint);
  }
}
