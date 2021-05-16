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

class RouteBuilder {
  String _pattern;
  late String _method;
  late u.UriTemplate _template;
  late u.UriParser _parser;
  Handler _endpoint;
  Pipeline _pipeline;

  String get pattern => _pattern;

  RouteBuilder(String method, this._pattern, Handler this._endpoint,
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

  void guard(Guard guard) {
    _pipeline = _pipeline.clone(guard);
  }

  Future<Response?> serve(Request req) async {
    req.params.load(_parser.parse(req.uri));
    return _pipeline.serve(req, _endpoint);
  }
}
