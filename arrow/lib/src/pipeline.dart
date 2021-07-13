import 'dart:async';

import 'request_middleware.dart';
import 'response_middleware.dart';
import 'endpoint.dart';
import 'request.dart';
import 'response.dart';
import 'guard.dart';

typedef Future<Request> _WrappedRequestHandler(Request req);
typedef Future<Response> _WrappedResponseHandler(Response res);

class Pipeline {
  final _syncRequestHandlers = <_WrappedRequestHandler>[];
  final _syncResponseHandlers = <_WrappedResponseHandler>[];
  final _asyncRequestHandlers = <_WrappedRequestHandler>[];
  final _asyncResponseHandlers = <_WrappedResponseHandler>[];
  // final Guard? _guard;

  Pipeline();

  Pipeline._clone(Pipeline src) {
    _syncRequestHandlers.addAll(List.from(src._syncRequestHandlers));
    _syncResponseHandlers.addAll(List.from(src._syncResponseHandlers));
    _asyncRequestHandlers.addAll(List.from(src._asyncRequestHandlers));
    _asyncResponseHandlers.addAll(List.from(src._asyncResponseHandlers));
  }

  Pipeline clone() {
    return Pipeline._clone(this);
  }

  _WrappedRequestHandler _wrapRequestHandler(
      RequestMiddleware middleware, bool useAlways) {
    return (Request req) async {
      if (useAlways) {
        return Future(() async => middleware(req));
      } else {
        return Future(() async {
          if (req.isAlive) {
            return middleware(req);
          } else {
            return req;
          }
        });
      }
    };
  }

  _WrappedResponseHandler _wrapResponseHandler(
      ResponseMiddleware middleware, bool useAlways) {
    return (Response res) async {
      if (useAlways) {
        return Future(() async => middleware(res));
      } else {
        return Future(() async {
          if (res.isAlive) {
            return middleware(res);
          } else {
            return res;
          }
        });
      }
    };
  }

  void onRequest(RequestMiddleware requestMiddleware,
      {bool runAsync = false, bool useAlways = false}) {
    if (runAsync) {
      _asyncRequestHandlers
          .add(_wrapRequestHandler(requestMiddleware, useAlways));
    } else {
      _syncRequestHandlers
          .add(_wrapRequestHandler(requestMiddleware, useAlways));
    }
  }

  void onResponse(ResponseMiddleware responseMiddleware,
      {bool runAsync = false, bool useAlways = false}) {
    if (runAsync) {
      _asyncResponseHandlers
          .add(_wrapResponseHandler(responseMiddleware, useAlways));
    } else {
      _syncResponseHandlers
          .add(_wrapResponseHandler(responseMiddleware, useAlways));
    }
  }

  Future<Response> serve(Request req, Endpoint endpoint,
      {bool forceHandlerToRun = false, Guard? guard}) async {
    if (guard != null) {
      if (!(await guard(req))) {
        return req.respond.forbidden();
      }
    }

    if (_syncRequestHandlers.isNotEmpty) {
      req = await _processSyncRequestHandlers(req, _syncRequestHandlers);
    }

    if (_asyncRequestHandlers.isNotEmpty) {
      req = await _processAsyncRequestHandlers(req, _asyncRequestHandlers);
    }

    var res = (req.isAlive || forceHandlerToRun)
        ? await endpoint(req)
        : req.respond.serverError();

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
    for (final handler in handlers) {
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
