import 'dart:async';
import 'dart:convert' show json;
import 'dart:io' as io;
import 'package:arrow/arrow.dart';
import 'package:uri/uri.dart';

import 'route.dart';
import 'pipeline.dart';
import 'constants.dart';
import 'recoverer.dart';
import 'static_files.dart';

typedef Router RouterBuilder();

class Router {
  String _pattern = '';
  late UriTemplate _template;
  late UriParser _parser;

  Pipeline _pipeline = Pipeline();

  List<Router> _childRouters = <Router>[];
  Map<String, List<Route>> _routeTree = Map<String, List<Route>>();
  final List<StaticMount> _staticMounts = <StaticMount>[];

  Handler? _notFoundHandler;

  Recoverer _recoverer = _defaultRecoverer;
  final bool _shouldRecover;

  /// A [Router] is created to specify the URIs (routes) that the server can handle. Routers
  /// take middleware, which are functions that are executed on [Request]s
  /// ([RequestMiddleware]) and [Response]es ([ResponseMiddleware]). Routers also
  /// take a [Handler], which is the function to execute for the specified
  /// route.
  /// Middleware are executed in the following order:
  /// 1. [RequestMiddleware] in the order they are added to the [Router]
  /// 2. The request [Handler] which initiates the response
  /// 3. [ResponseMiddleware] in the order they are added to the [Router]
  /// A [Router] can also be created as a group, which is a sub-router for routes
  /// that have the same partial URIs. These groups can inherit or have their own
  /// middleware stack.
  /// A [Router] can optionally be assigned a [Handler] to be used for not found routes
  /// (i.e. 404 errors) and/or a [Recoverer] from unhandled errors and exceptions.
  Router(
      {bool shouldRecover = true,
      Recoverer? recoverer})
      : _shouldRecover = shouldRecover {
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
      {bool useAlways = false}) {
    if (!_pipelineIsClosed()) {
      _pipeline.onRequest(requestMiddleware, useAlways: useAlways);
    }
  }

  /// Add a [ResponseMiddleware] to this router's middleware stack
  void onResponse(ResponseMiddleware responseMiddleware,
      {bool useAlways = false}) {
    if (!_pipelineIsClosed()) {
      _pipeline.onResponse(responseMiddleware, useAlways: useAlways);
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

  // Could inject a pipeline into the route function
  // Would it replace the pipeline in progress of being built?
  // Could also have a router.pipeline(Pipeline) function that replaces
  // whatever is already stacked in the pipeline (does that make sense?)

  /// Create a GET route with the specified URI pattern and handler
  Route get(String pattern, Handler endpoint, {Pipeline? pipeline}) {
    pattern = _formatPattern(pattern);
    Route route = Route(
        RouterMethods.GET, _pattern + pattern, endpoint, pipeline ?? _pipeline);
    _storeRouteInTree(RouterMethods.GET, route);
    return route;
  }

  /// Create a POST route with the specified URI pattern and handler
  Route post(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    Route route =
        Route(RouterMethods.POST, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.POST, route);
    return route;
  }

  /// Create a PUT route with the specified URI pattern and handler
  Route put(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    Route route =
        Route(RouterMethods.PUT, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.PUT, route);
    return route;
  }

  /// Create a DELETE route with the specified URI pattern and handler
  Route delete(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    Route route =
        Route(RouterMethods.DELETE, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.DELETE, route);
    return route;
  }

  /// Create a PATCH route with the specified URI pattern and handler
  ///
  /// PATCH is used for partial updates to a resource, as opposed to PUT
  /// which replaces the entire resource.
  ///
  /// ```dart
  /// router.patch('/users/{id}', (req) async {
  ///   final id = req.params.get('id');
  ///   // Apply partial update...
  ///   return req.respond.ok(data: {'id': id, 'updated': true});
  /// });
  /// ```
  Route patch(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    Route route =
        Route(RouterMethods.PATCH, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.PATCH, route);
    return route;
  }

  /// Create a HEAD route with the specified URI pattern and handler
  ///
  /// HEAD is identical to GET but returns only headers, no body.
  /// Useful for checking resource existence or metadata without
  /// transferring the full response body.
  ///
  /// ```dart
  /// router.head('/users/{id}', (req) async {
  ///   // Check if user exists, return status only
  ///   return req.respond.code(200);
  /// });
  /// ```
  Route head(String pattern, Handler endpoint) {
    pattern = _formatPattern(pattern);
    Route route =
        Route(RouterMethods.HEAD, _pattern + pattern, endpoint, _pipeline);
    _storeRouteInTree(RouterMethods.HEAD, route);
    return route;
  }

  /// Mount a directory for serving static files at a URL prefix.
  ///
  /// Static mounts are checked before route matching. If a file exists
  /// under [directory] matching the request path, it is served directly.
  /// Otherwise the request falls through to normal route matching.
  ///
  /// Only responds to GET and HEAD requests.
  ///
  /// ```dart
  /// // Serve files from 'web/public' at '/public/*'
  /// router.static('/public', 'web/public');
  ///
  /// // With custom config
  /// router.static('/assets', 'web/assets', StaticFilesConfig(
  ///   maxAge: 86400,
  ///   etag: true,
  /// ));
  /// ```
  void serveStaticFiles(String urlPrefix, String directory,
      [StaticFilesConfig? config]) {
    if (!urlPrefix.startsWith('/')) {
      urlPrefix = '/$urlPrefix';
    }
    if (urlPrefix.endsWith('/')) {
      urlPrefix = urlPrefix.substring(0, urlPrefix.length - 1);
    }
    _staticMounts.add(StaticMount(urlPrefix, directory, config));
  }

  static Future<Response> _defaultNotFoundHandler(Request req) async {
    return req.respond.notFound();
  }

  /// Add a custom handler to execute when a route is not found. By default,
  /// the router simply returns a 404 error.
  void notFound(Handler handler) {
    _notFoundHandler = handler;
  }

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
    return req.respond.isComplete
        ? req.respond.response
        : req.respond.serverError();
  }

  /// Add a [Recoverer] function to execute when an unhandled exception
  /// or error occurs. The default recoverer prints the Exception/Error
  /// message and stack trace.
  void recover(Recoverer recoverer) {
    _recoverer = recoverer;
  }

  void _storeRouteInTree(method, route) {
    if (!_routeTree.containsKey(method)) {
      _routeTree[method] = <Route>[];
    }
    _routeTree[method]!.add(route);
  }

  Future<Response?> _serve(Request req) async {
    // Check static file mounts first.
    if (req.isAlive && _staticMounts.isNotEmpty) {
      for (final mount in _staticMounts) {
        final result = await mount.tryServe(req);
        if (result != null) return result;
      }
    }

    if (req.isAlive && _childRouters.length > 0) {
      final childRouter = await _findChildRouter(req);
      if (childRouter != null) {
        return childRouter._serve(req);
      }
    }

    if (req.isAlive && _routeTree.length > 0) {
      var route = await _findRoute(req);
      if (route == null) {
        // Run the regular pipeline so cross-cutting middleware (e.g. CORS
        // preflight) can handle the request even when no route matches the
        // method.  If middleware cancels the request (OPTIONS → 200) the
        // not-found handler is skipped; otherwise it returns 404 with any
        // headers the middleware set (e.g. Access-Control-Allow-Origin).
        return _pipeline.serve(
            req, _notFoundHandler ?? _defaultNotFoundHandler);
      } else {
        return route.serve(req);
      }
    }

    // Static mounts or child routers exist but nothing matched — 404.
    if (req.isAlive && (_staticMounts.isNotEmpty || _childRouters.isNotEmpty)) {
      return _pipeline.serve(
          req, _notFoundHandler ?? _defaultNotFoundHandler);
    }

    return req.respond.isComplete
        ? req.respond.response
        : req.respond.serverError();
  }

  Future<Response?> serve(Request req) async {
    try {
      return await _serve(req);
    } on HttpException catch (e) {
      if (!_shouldRecover) rethrow;
      return _handleHttpException(req, e);
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

  /// Converts an [HttpException] to Arrow's standard error response.
  Response _handleHttpException(Request req, HttpException e) {
    final encoded = json.encode({
      'ok': false,
      'errorMessage': e.message,
      'errors': e.errors,
    });
    final srcResponse = req.innerRequest.response;
    srcResponse.headers.set(
        io.HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    srcResponse.statusCode = e.statusCode;
    srcResponse.write(encoded);
    req.cancel();
    return Response(req);
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

  Future<Route?> _findRoute(Request req) async {
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
