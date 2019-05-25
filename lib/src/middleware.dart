import 'package:arrow/src/handler.dart';
import 'package:arrow/src/request_middleware.dart';
import 'package:arrow/src/response_middleware.dart';

class Middleware {
  RequestMiddleware _preProcess;
  ResponseMiddleware _postProcess;
  Handler _errorProcess;

  RequestMiddleware get preProcess => _preProcess;

  ResponseMiddleware get postProcess => _postProcess;

  Handler get errorProcess => _errorProcess;

  bool _useParallel = false;

  bool get useParallel => _useParallel;
  bool _useAlways = false;

  bool get useAlways => _useAlways;

  Middleware(
      {RequestMiddleware pre,
      ResponseMiddleware post,
      Handler error,
      bool useParallel: false,
      bool useAlways: false}) {
    if (pre != null) {
      _preProcess = pre;
    }
    if (post != null) {
      _postProcess = post;
    }
    if (error != null) {
      _errorProcess = error;
    }
    _useParallel = useParallel;
    _useAlways = useAlways;
  }
}

Middleware CreateMiddleware(
    {RequestMiddleware pre,
    ResponseMiddleware post,
    Handler error,
    bool useParallel: false,
    useAlways: false}) {
  return Middleware(
      pre: pre,
      post: post,
      error: error,
      useParallel: useParallel,
      useAlways: useAlways);
}
