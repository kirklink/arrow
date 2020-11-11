import 'dart:async';
import 'package:uri/uri.dart';

import 'package:arrow/src/request.dart';
import 'package:arrow/src/response.dart';
import 'package:arrow/src/middleware.dart';
import 'package:arrow/src/handler.dart';
import 'package:arrow/src/request_middleware.dart';
import 'package:arrow/src/response_middleware.dart';
import 'package:arrow/src/route.dart';
import 'package:arrow/src/pipeline.dart';
import 'package:arrow/src/constants.dart';
import 'package:arrow/src/recover.dart';

typedef Router RouterBuilder();

class Router {
  String _pattern = '';
  UriTemplate _template;
  UriParser _parser;

  Pipeline _pipeline = Pipeline();

  List<Router> _childRouters = List<Router>();
  Map<String, List<Route>> _routeTree = Map<String, List<Route>>();

  Route _notFoundDefault;
  Route _notFoundCustom;

  Recoverer _recover;

  Router(
      {Pipeline notFoundPipeline,
      Handler notFoundHandler,
      Pipeline serverErrorPipeline,
      Handler serverErrorHandler}) {
    if (notFoundPipeline != null && notFoundHandler != null) {
      _notFoundCustom = Route('GET', '', notFoundHandler, notFoundPipeline);
    } else if (notFoundPipeline == null && notFoundHandler == null) {
      _notFoundDefault = Route('GET', '', _notFoundDefaultHandler, Pipeline());
    } else {
      throw ArgumentError(
          'Pipeline and Handler must be provided to set up the Not Found (404) route.');
    }
  }

  Router._group(String pattern, this._pipeline) {
    _pattern = _formatPattern(pattern);
    _template = UriTemplate(_pattern);
    _parser = UriParser(_template, queryParamsAreOptional: true);
  }

  Router Group(String pattern) {
    pattern = _formatPattern(pattern);
    Router child = Router._group(_pattern + pattern, _pipeline.Clone());
    _childRouters.add(child);
    return child;
  }

  void printRoutes() {
    _routeTree.forEach((k, v) {
      v.sort((a, b) => a.pattern.compareTo(b.pattern));
      v.forEach((r) => print('${(k + ':').padRight(5)} ${r.pattern}'));
    });
    _childRouters.forEach((r) => r.printRoutes());
  }

  bool _pipelineIsClosed() {
    if (_childRouters.length > 0 || _routeTree.length > 0) {
      throw ArgumentError('Cannot add middleware after sub-routers or routes.');
    } else {
      return false;
    }
  }

  void useSerial(
      {RequestMiddleware pre,
      ResponseMiddleware post,
      Handler error,
      bool useAlways: false}) {
    if (!_pipelineIsClosed()) {
      _pipeline.use(
          Middleware(pre: pre, post: post, error: error, useAlways: useAlways));
    }
  }

  void useParallel(
      {RequestMiddleware pre,
      ResponseMiddleware post,
      Handler error,
      bool useAlways: false}) {
    if (!_pipelineIsClosed()) {
      _pipeline.use(Middleware(
          pre: pre,
          post: post,
          error: error,
          useParallel: true,
          useAlways: useAlways));
    }
  }

  void use(Middleware middleware) {
    if (!_pipelineIsClosed()) {
      _pipeline.use(middleware);
    }
  }

  void clearPipeline() {
    _pipeline = Pipeline();
  }

  Route GET(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    Route route =
        Route(RouterMethods.GET, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.GET, route);
    return route;
  }

  Route POST(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    Route route =
        Route(RouterMethods.POST, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.POST, route);
    return route;
  }

  Route PUT(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    Route route =
        Route(RouterMethods.PUT, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.PUT, route);
    return route;
  }

  Route DELETE(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    Route route =
        Route(RouterMethods.DELETE, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.DELETE, route);
    return route;
  }

  Future<Response> _notFoundDefaultHandler(Request req) async {
    var res = req.response;
    res.send.notFound();
    return res;
  }

  Route NOT_FOUND(Handler endpoint) {
    if (_notFoundCustom != null)
      throw Exception('Custom NOT_FOUND route is already set.');
    if (_notFoundDefault == null)
      throw Exception(
          'Something went wrong. Cannot add NOT_FOUND to a child router. This is a bug.');
    _notFoundCustom = Route(RouterMethods.GET, '', endpoint, _pipeline);
    return _notFoundCustom;
  }

  Response _defaultRecoverer(Request req,
      {Exception exception, StackTrace stacktrace, Error error}) {
    print('!! -- Recover -- !!');
    print('Exception:');
    print(exception);
    print('Error:');
    print(error);
    print('Stacktrace:');
    print(stacktrace);
    print('-- End Recover --');
    var res = req.response;
    res.send.serverError();
    return res;
  }

  void RECOVER([Recoverer recover]) {
    _recover = recover == null ? _defaultRecoverer : recover;
    return;
  }

  void _storeRouteInTree(method, route) {
    if (!_routeTree.containsKey(method)) {
      _routeTree[method] = List<Route>();
    }
    _routeTree[method].add(route);
  }

  Future<Response> _serve(Request req) async {
    if (req.isAlive && _childRouters.length > 0) {
      var childRouter = await _findChildRouter(req);
      if (childRouter != null) {
        var res = childRouter._serve(req);
        return res;
      }
    }
    if (req.isAlive && _routeTree.length > 0) {
      var route = await _findRoute(req);
      if (route != null) {
        var res = await route.serve(req);
        return res;
      }
    }
    return null;
  }

  Future<Response> serve(Request req) async {
    Future<Response> res;
    try {
      res = _serve(req);
    } on Error catch (e, s) {
      return _recover(req, error: e, stacktrace: s);
    } catch (e, s) {
      if (_recover == null) {
        rethrow;
      } else {
        return _recover(req, exception: e, stacktrace: s);
      }
    }
    if (res == null) {
      if (_notFoundDefault != null) {
        return _notFoundCustom.serve(req);
      } else {
        return _notFoundDefault.serve(req);
      }
    } else {
      return res;
    }
  }

  bool canHandle(Uri uri) {
    return _parser.matches(uri);
  }

  Future<Router> _findChildRouter(Request req) async {
    for (Router child in _childRouters) {
      if (child.canHandle(req.uri)) {
        return child;
      }
    }
    return null;
  }

  Future<Route> _findRoute(Request req) async {
    var routes = _routeTree[req.method];
    if (routes == null) return null;
    for (Route route in routes) {
      if (route.canHandle(req.method, req.uri)) {
        return route;
      }
    }
    return null;
  }

  String _formatPattern(String pattern) {
    if (!pattern.startsWith('/')) pattern = '/' + pattern;
    if (pattern.endsWith('/')) {
      pattern = pattern.substring(0, pattern.length - 1);
    }
    return pattern;
  }
}
