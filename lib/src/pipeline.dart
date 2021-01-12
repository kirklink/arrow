import 'dart:async';

import 'middleware.dart';
import 'handler.dart';
import 'request.dart';
import 'response.dart';

typedef Future<Request> WrappedRequestHandler(Request req);
typedef Future<Response> WrappedResponseHandler(Response res);

class Pipeline {
  List<WrappedRequestHandler> _syncRequestHandlers = List<WrappedRequestHandler>();
  List<WrappedResponseHandler> _syncResponseHandlers = List<WrappedResponseHandler>();
  List<WrappedRequestHandler> _asyncRequestHandlers = List<WrappedRequestHandler>();
  List<WrappedResponseHandler> _asyncResponseHandlers = List<WrappedResponseHandler>();

  Pipeline();

  Pipeline._clone(
      List<WrappedRequestHandler> syncRequestHandlers,
      List<WrappedResponseHandler> syncResponseHandlers,
      List<WrappedRequestHandler> asyncRequestHandlers,
      List<WrappedResponseHandler> asyncResponseHandlers) {
    _syncRequestHandlers = List.from(syncRequestHandlers);
    _syncResponseHandlers = List.from(syncResponseHandlers);
    _asyncRequestHandlers = List.from(asyncRequestHandlers);
    _asyncResponseHandlers = List.from(asyncResponseHandlers);
  }

  Pipeline Clone() {
    return Pipeline._clone(_syncRequestHandlers, _syncResponseHandlers,
        _asyncRequestHandlers, _asyncResponseHandlers);
  }

  WrappedRequestHandler _wrapRequestHandler(Middleware middleware) {
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

  WrappedResponseHandler _wrapResponseHandler(Middleware middleware) {
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
      Request req, List<WrappedRequestHandler> handlers) async {
    for (var handler in handlers) {
      req = await handler(req);
    }
    return req;
  }

  Future<Response> _processSyncResponseHandlers(
      Response res, List<WrappedResponseHandler> handlers) async {
    for (var handler in handlers) {
      res = await handler(res);
    }
    return res;
  }

  Future<Request> _processAsyncRequestHandlers(
      Request req, List<WrappedRequestHandler> handlers) async {
    if (handlers.length == 0) return Future.value(req);
    List<Future<Request>> futures = <Future<Request>>[];
    for (var handler in handlers) {
      futures.add(handler(req));
    }
    return Future.wait(futures).then((result) => result[result.length - 1]);
  }

  Future<Response> _processAsyncResponseHandlers(
      Response res, List<WrappedResponseHandler> handlers) async {
    if (handlers.length == 0) return Future.value(res);
    List<Future<Response>> futures = <Future<Response>>[];
    for (var handler in handlers) {
      futures.add(handler(res));
    }
    return Future.wait(futures).then((result) => result[result.length - 1]);
  }
}
