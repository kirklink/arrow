import 'dart:async';

import 'middleware.dart';
import 'handler.dart';
import 'request.dart';
import 'response.dart';
import 'guard.dart';

typedef Future<Request> _WrappedRequestHandler(Request req);
typedef Future<Response> _WrappedResponseHandler(Response res);

class Pipeline {
  final _syncRequestHandlers = List<_WrappedRequestHandler>();
  final _syncResponseHandlers = List<_WrappedResponseHandler>();
  final _asyncRequestHandlers = List<_WrappedRequestHandler>();
  final _asyncResponseHandlers = List<_WrappedResponseHandler>();
  final GuardBuilder _guard;

  Pipeline([this._guard]);

  Pipeline._clone(Pipeline src, [this._guard]) {
    _syncRequestHandlers.addAll(List.from(src._syncRequestHandlers));
    _syncResponseHandlers.addAll(List.from(src._syncResponseHandlers));
    _asyncRequestHandlers.addAll(List.from(src._asyncRequestHandlers));
    _asyncResponseHandlers.addAll(List.from(src._asyncResponseHandlers));
  }

  Pipeline clone([GuardBuilder guard]) {
    return Pipeline._clone(this, guard);
  }

  _WrappedRequestHandler _wrapRequestHandler(Middleware middleware) {
    return (Request req) async {
      if (middleware.useAlways) {
        return Future(() async => middleware.requestMiddleware(req));
      } else {
        return Future(() async {
          if (req.isAlive) {
            return middleware.requestMiddleware(req);
          } else {
            return req;
          }
        });
      }
    };
  }

  _WrappedResponseHandler _wrapResponseHandler(Middleware middleware) {
    return (Response res) async {
      if (middleware.useAlways) {
        return Future(() async => middleware.responseMiddleware(res));
      } else {
        return Future(() async {
          if (res.isAlive) {
            return middleware.responseMiddleware(res);
          } else {
            return res;
          }
        });
      }
    };
  }

  void use(Middleware middleware) {
    if (middleware.runAsync) {
      if (middleware.requestMiddleware != null) {
        _asyncRequestHandlers.add(_wrapRequestHandler(middleware));
      }
      if (middleware.responseMiddleware != null) {
        _asyncResponseHandlers.insert(0, _wrapResponseHandler(middleware));
      }
    } else {
      if (middleware.requestMiddleware != null) {
        _syncRequestHandlers.add(_wrapRequestHandler(middleware));
      }
      if (middleware.responseMiddleware != null) {
        _syncResponseHandlers.insert(0, _wrapResponseHandler(middleware));
      }
    }
  }

  Future<Response> serve(Request req, Handler endpoint) async {
    if (_guard != null) {
      final guard = await _guard.evaluate(req);
      if (!guard.allows) {
        req.response.send.forbidden();
      }
      req = guard.request;
    }

    if (_syncRequestHandlers.isNotEmpty) {
      req = await _processSyncRequestHandlers(req, _syncRequestHandlers);
    }

    if (_asyncRequestHandlers.isNotEmpty) {
      req = await _processAsyncRequestHandlers(req, _asyncRequestHandlers);
    }

    Response res;
    if (req.isAlive) {
      res = await endpoint(req);
    } else {
      res = req.response;
    }
    ;

    if (_asyncResponseHandlers.isNotEmpty) {
      res = await _processAsyncResponseHandlers(res, _asyncResponseHandlers);
    }

    if (_syncResponseHandlers.isNotEmpty) {
      res = await _processSyncResponseHandlers(res, _syncResponseHandlers);
    }

    return res;
  }

  Future<Request> _processSyncRequestHandlers(
      Request req, List<_WrappedRequestHandler> handlers) async {
    for (var handler in handlers) {
      req = await handler(req);
    }
    return req;
  }

  Future<Response> _processSyncResponseHandlers(
      Response res, List<_WrappedResponseHandler> handlers) async {
    for (var handler in handlers) {
      res = await handler(res);
    }
    return res;
  }

  Future<Request> _processAsyncRequestHandlers(
      Request req, List<_WrappedRequestHandler> handlers) async {
    if (handlers.length == 0) return Future.value(req);
    List<Future<Request>> futures = <Future<Request>>[];
    for (var handler in handlers) {
      futures.add(handler(req));
    }
    return Future.wait(futures).then((result) => result[result.length - 1]);
  }

  Future<Response> _processAsyncResponseHandlers(
      Response res, List<_WrappedResponseHandler> handlers) async {
    if (handlers.length == 0) return Future.value(res);
    List<Future<Response>> futures = <Future<Response>>[];
    for (var handler in handlers) {
      futures.add(handler(res));
    }
    return Future.wait(futures).then((result) => result[result.length - 1]);
  }
}
