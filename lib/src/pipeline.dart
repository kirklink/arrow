import 'dart:async';

import 'request_middleware.dart';
import 'response_middleware.dart';
import 'handler.dart';
import 'request.dart';
import 'response.dart';
import 'guard.dart';

typedef Future<Request> _WrappedRequestHandler(Request req);
typedef Future<Response> _WrappedResponseHandler(Response res);

class Pipeline {
  final _requestHandlers = <_WrappedRequestHandler>[];
  final _responseHandlers = <_WrappedResponseHandler>[];
  final Guard? _guard;

  Pipeline([this._guard]);

  Pipeline._clone(Pipeline src, [this._guard]) {
    _requestHandlers.addAll(List.from(src._requestHandlers));
    _responseHandlers.addAll(List.from(src._responseHandlers));
  }

  Pipeline clone([Guard? guard]) {
    return Pipeline._clone(this, guard);
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
      {bool useAlways = false}) {
    _requestHandlers
        .add(_wrapRequestHandler(requestMiddleware, useAlways));
  }

  void onResponse(ResponseMiddleware responseMiddleware,
      {bool useAlways = false}) {
    _responseHandlers
        .add(_wrapResponseHandler(responseMiddleware, useAlways));
  }

  Future<Response> serve(Request req, Handler endpoint,
      {bool forceHandlerToRun = false}) async {
    if (_guard != null) {
      final guardAllows = await _guard!(req);
      if (!guardAllows) {
        return req.respond.forbidden();
      }
    }

    if (_requestHandlers.isNotEmpty) {
      req = await _processRequestHandlers(req, _requestHandlers);
    }

    var res = (req.isAlive || forceHandlerToRun)
        ? await endpoint(req)
        : req.respond.serverError();

    if (_responseHandlers.isNotEmpty) {
      res = await _processResponseHandlers(res, _responseHandlers);
    }

    return res;
  }

  Future<Request> _processRequestHandlers(
      Request req, List<_WrappedRequestHandler> handlers) async {
    for (var handler in handlers) {
      req = await handler(req);
    }
    return req;
  }

  Future<Response> _processResponseHandlers(
      Response res, List<_WrappedResponseHandler> handlers) async {
    for (var handler in handlers) {
      res = await handler(res);
    }
    return res;
  }
}
