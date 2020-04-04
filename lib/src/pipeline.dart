import 'dart:async';

import 'package:arrow/src/middleware.dart';
import 'package:arrow/src/handler.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/response.dart';

typedef Future<Request> WrappedPreHandler(Request req);
typedef Future<Response> WrappedPostHandler(Response res);

class Pipeline {
  List<WrappedPreHandler> _serialPreHandlers = List<WrappedPreHandler>();
  List<WrappedPostHandler> _serialPostHandlers = List<WrappedPostHandler>();
  List<WrappedPreHandler> _parallelPreHandlers = List<WrappedPreHandler>();
  List<WrappedPostHandler> _parallelPostHandlers = List<WrappedPostHandler>();

  Pipeline();

  Pipeline._clone(
      List<WrappedPreHandler> serialPreHandlers,
      List<WrappedPostHandler> serialPostHandlers,
      List<WrappedPreHandler> parallelPreHandlers,
      List<WrappedPostHandler> parallelPostHandlers) {
    _serialPreHandlers = List.from(serialPreHandlers);
    _serialPostHandlers = List.from(serialPostHandlers);
    _parallelPreHandlers = List.from(parallelPreHandlers);
    _parallelPostHandlers = List.from(parallelPostHandlers);
  }

  Pipeline Clone() {
    return Pipeline._clone(_serialPreHandlers, _serialPostHandlers,
        _parallelPreHandlers, _parallelPostHandlers);
  }

  WrappedPreHandler _wrapPreProcess(Middleware middleware) {
    return (Request req) async {
      if (middleware.useAlways) {
        return Future(() async => middleware.preProcess(req));
      } else {
        return Future(() async {
          if (req.isAlive) {
            return middleware.preProcess(req);
          } else {
            return req;
          }
        });
      }
    };
  }

  WrappedPostHandler _wrapPostProcess(Middleware middleware) {
    return (Response res) async {
      if (middleware.useAlways) {
        return Future(() async => middleware.postProcess(res));
      } else {
        return Future(() async {
          if (res.isAlive) {
            return middleware.postProcess(res);
          } else {
            return res;
          }
        });
      }
    };
  }

  void use(Middleware middleware) {
    if (middleware.useParallel) {
      if (middleware.preProcess != null) {
        _parallelPreHandlers.add(_wrapPreProcess(middleware));
      }
      if (middleware.postProcess != null) {
        _parallelPostHandlers.insert(0, _wrapPostProcess(middleware));
      }
    } else {
      if (middleware.preProcess != null) {
        _serialPreHandlers.add(_wrapPreProcess(middleware));
      }
      if (middleware.postProcess != null) {
        _serialPostHandlers.insert(0, _wrapPostProcess(middleware));
      }
    }
  }

  Future<Response> serve(Request req, Handler endpoint) async {
    req = await _processPreSerial(req, _serialPreHandlers);

    req = await _processPreParallel(req, _parallelPreHandlers);

    Response res;
    if (req.isAlive) {
      res = await endpoint(req);
    } else {
      res = req.response;
    }
    ;

    res = await _processPostParallel(res, _parallelPostHandlers);

    res = await _processPostSerial(res, _serialPostHandlers);

    return res;
  }

  Future<Request> _processPreSerial(
      Request req, List<WrappedPreHandler> handlers) async {
    for (var handler in handlers) {
      req = await handler(req);
    }
    return req;
  }

  Future<Response> _processPostSerial(
      Response res, List<WrappedPostHandler> handlers) async {
    for (var handler in handlers) {
      res = await handler(res);
    }
    return res;
  }

  Future<Request> _processPreParallel(
      Request req, List<WrappedPreHandler> handlers) async {
    if (handlers.length == 0) return Future.value(req);
    List<Future<Request>> futures = <Future<Request>>[];
    for (var handler in handlers) {
      futures.add(handler(req));
    }
    return Future.wait(futures).then((result) => result[result.length - 1]);
  }

  Future<Response> _processPostParallel(
      Response res, List<WrappedPostHandler> handlers) async {
    if (handlers.length == 0) return Future.value(res);
    List<Future<Response>> futures = <Future<Response>>[];
    for (var handler in handlers) {
      futures.add(handler(res));
    }
    return Future.wait(futures).then((result) => result[result.length - 1]);
  }
}
