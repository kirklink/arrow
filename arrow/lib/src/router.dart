import 'dart:async';
import 'package:arrow/arrow.dart';
import 'package:uri/uri.dart';

import 'request.dart';
import 'response.dart';
import 'handler.dart';
import 'route_builder.dart';
import 'route.dart';
import 'pipeline.dart';
import 'constants.dart';
import 'recoverer.dart';

typedef Router RouterBuilder();

class Router {
  String _pattern = '';
  late UriTemplate _template;
  late UriParser _parser;

  Pipeline _pipeline = Pipeline();

  List<Router> _childRouters = <Router>[];
  Map<String, List<RouteBuilder>> _routeTree =
      Map<String, List<RouteBuilder>>();

  var _notFoundPipeline = Pipeline();

  Recoverer _recoverer = _defaultRecoverer;
  final bool _shouldRecover;

  /// A [Router] is created to specify the URIs (routes) that the server can handle. Routers
  /// take middleware, which are functions that are executed on [Request]s
  /// ([RequestMiddleware]) and [Response]es ([ResponseMiddleware]). Routers also
  /// take a [Handler], which is the function to execute for the specified
  /// route.
  /// Middleware are executed in the following order:
  /// 1. Synchronous [RequestMiddleware] in the order they are added to the [Router]
  /// 2. Asynchronous [RequestMiddleware] asynchronously in no guaranteed order until they are all completed
  /// 3. The request [Handler] which initiates the response
  /// 4. Asynchronous [ResponseMiddleware] asynchronously in no guaranteed order until they are all completed
  /// 5. Synchronous [ResponseMiddleware] in the order they are added to the [Router]
  /// A [Router] can also be created as a group, which is a sub-router for routes
  /// that have the same partial URIs. These groups can inherit or have their own
  /// middleware stack.
  /// A [Router] can optionally be assigned a [Handler] to be used for not found routes
  /// (i.e. 404 errors) and/or a [Recoverer] from unhandled errors and exceptions.
  Router(
      {Pipeline? notFoundPipeline,
      bool shouldRecover = true,
      Recoverer? recoverer})
      : _shouldRecover = shouldRecover {
    if (notFoundPipeline != null) {
      _notFoundPipeline = notFoundPipeline;
    }
    if (recoverer != null) {
      _recoverer = recoverer;
    }
  }

  Router._group(
      String pattern, this._pipeline, this._shouldRecover, this._recoverer) {
    _pattern = _formatPattern(pattern);
    _template = UriTemplate(_pattern);
    _parser = UriParser(_template, queryParamsAreOptional: true);
  }

  /// Create a new Router Group (sub-router) that shares part of a URI
  /// with its child routes. By default the new group inherits the Middleware
  /// stack from its parent but the Middleware stack can have Middleware added
  /// or completely cleared.
  Router group(String pattern) {
    pattern = _formatPattern(pattern);
    Router child = Router._group(
        _pattern + pattern, _pipeline.clone(), _shouldRecover, _recoverer);
    _childRouters.add(child);
    return child;
  }

  /// A convenience method that will print all of the routes that this
  /// Router will handle when the router is initialized.
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

  /// Add a [RequestMiddleware] to this router's middleware stack
  void onRequest(RequestMiddleware requestMiddleware,
      {bool runAsync = false, bool useAlways = false}) {
    if (!_pipelineIsClosed()) {
      _pipeline.onRequest(requestMiddleware,
          runAsync: runAsync, useAlways: useAlways);
    }
  }

  /// Add a [ResponseMiddleware] to this router's middleware stack
  void onResponse(ResponseMiddleware responseMiddleware,
      {bool runAsync = false, bool useAlways = false}) {
    if (!_pipelineIsClosed()) {
      _pipeline.onResponse(responseMiddleware,
          runAsync: runAsync, useAlways: useAlways);
    }
  }

  /// Removes all the [Middleware] from the stack. Useful for clearing and
  /// then redefining the middleware for a router group.
  void clearPipeline() {
    _pipeline = Pipeline();
  }

  void pipeline(Pipeline pipeline) {
    _pipeline = pipeline;
  }

  void route(Route route) {}

  /// Create a GET route with the specified URI pattern and handler
  RouteBuilder get(String pattern, Handler endpoint, {Pipeline? pipeline}) {
    pattern = _formatPattern(pattern);
    RouteBuilder route = RouteBuilder(
        RouterMethods.GET, _pattern + pattern, endpoint, pipeline ?? _pipeline);
    _storeRouteInTree(RouterMethods.GET, route);
    return route;
  }

  /// Create a POST route with the specified URI pattern and handler
  RouteBuilder post(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    RouteBuilder route = RouteBuilder(
        RouterMethods.POST, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.POST, route);
    return route;
  }

  /// Create a PUT route with the specified URI pattern and handler
  RouteBuilder put(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    RouteBuilder route = RouteBuilder(
        RouterMethods.PUT, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.PUT, route);
    return route;
  }

  /// Create a DELETE route with the specified URI pattern and handler
  RouteBuilder delete(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    RouteBuilder route = RouteBuilder(
        RouterMethods.DELETE, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.DELETE, route);
    return route;
  }

  static Future<Response?> _notFoundHandler(Request req) async {
    return req.respond.notFound();
  }

  /// Add a custom handler to execute when a route is not found. By default,
  /// the router simply returns a 404 error.
  // Route notFound(Handler handler) {
  //   if (_notFoundCustom != null)
  //     throw Exception('Custom NOT_FOUND route is already set.');
  //   if (_notFoundDefault == null)
  //     throw Exception(
  //         'Something went wrong. Cannot add NOT_FOUND to a child router. This is a bug.');
  //   _notFoundCustom = Route(RouterMethods.GET, '', handler, _pipeline);
  //   return _notFoundCustom;
  // }

  static Future<Response?> _defaultRecoverer(Request req,
      {Exception? exception, StackTrace? stacktrace, Error? error}) async {
    print('!! -- Recover -- !!');
    print('Exception:');
    print(exception);
    print('Error:');
    print(error);
    print('Stacktrace:');
    print(stacktrace);
    print('-- End Recover --');
    return req.respond.serverError();
  }

  /// Add a [Recoverer] function to execute when an unhandled exception
  /// or error occurs. If added but a custom Recoverer is not provided, the default
  /// Recover prints the Exception/Error message and stack trace.
  // void recover([Recoverer recoverer]) {
  //   if (recoverer != null) {
  //     _recoverer = recoverer;
  //   }
  //   return;
  // }

  void _storeRouteInTree(method, route) {
    if (!_routeTree.containsKey(method)) {
      _routeTree[method] = <RouteBuilder>[];
    }
    _routeTree[method]!.add(route);
  }

  Future<Response?> _serve(Request req) async {
    if (req.isAlive && _childRouters.length > 0) {
      final childRouter = await _findChildRouter(req);
      if (childRouter != null) {
        return childRouter._serve(req);
      }
    }

    if (req.isAlive && _routeTree.length > 0) {
      var route = await _findRoute(req);
      if (route == null) {
        req.cancel();
        return _notFoundPipeline.serve(req, _notFoundHandler,
            forceHandlerToRun: true);
      } else {
        return route.serve(req);
      }
    }
    return req.respond.serverError();
  }

  Future<Response?> serve(Request req) async {
    try {
      return await _serve(req);
    } on Error catch (e, s) {
      if (!_shouldRecover) {
        rethrow;
      } else {
        return await _recoverer(req, error: e, stacktrace: s);
      }
    } on Exception catch (e, s) {
      if (!_shouldRecover) {
        rethrow;
      } else {
        return await _recoverer(req, exception: e, stacktrace: s);
      }
    }
  }

  /// Returns true if the router base route matches part of the requested URI.
  /// This is used when matching route groups to URIs.
  bool canHandle(Uri uri) {
    return _parser.matches(uri);
  }

  Future<Router?> _findChildRouter(Request req) async {
    for (Router child in _childRouters) {
      if (child.canHandle(req.uri)) {
        return child;
      }
    }
    return null;
  }

  Future<RouteBuilder?> _findRoute(Request req) async {
    var routes = _routeTree[req.method];
    if (routes == null) return null;
    for (RouteBuilder route in routes) {
      if (route.canHandle(req.method, req.uri)) {
        return route;
      }
    }
    return null;
  }

  String _formatPattern(String pattern) {
    if (!pattern.startsWith('/') && !pattern.startsWith('{?')) {
      pattern = '/' + pattern;
    }
    if (pattern.endsWith('/')) {
      pattern = pattern.substring(0, pattern.length - 1);
    }
    return pattern;
  }

  static Pipeline createPipeline() {
    return Pipeline();
  }
}
