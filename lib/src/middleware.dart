import 'handler.dart';
import 'request_middleware.dart';
import 'response_middleware.dart';

/// A process performed on a [Request] before a [Handler] (a [RequestMiddleware]) and/or on a [Response]
/// after a [Handler] (a [ResponseMiddleware]).
///
/// A [Handler] can also be provided in case of an error in the Middleware execution.
///
/// [Middleware] is added to a [Request]/[Response] [Pipeline] and can be synchronous
/// where [runAsync] is false or asynchronous where [runAsync] is true. Middleware
/// can be forced to run when [runAlways] is set to true; this is helpful for Middleware
/// such as loggers, which should always run regardles of the Request/Response status.
///

///
/// Synchronous Middleware are not guaranteed to run if a prior Middleware aborts the
/// Request/Response and [runAlways] is false. Asynchronous Middleware are not guaranteed
/// to run if a sibling asynchronous Middleware finishes first and aborts the Request/Response.
/// Asynchronous Middleware may complete in any order so they should be used carefully;
/// generally not to modify the Request/Response if other asynchronous Middleware depend
/// on the modification or to spawn related but independent processes such as storing a request
/// count to a database or retrieving multiple services a handler might depend on.
class Middleware {
  RequestMiddleware _preProcess;
  ResponseMiddleware _postProcess;
  Handler _errorProcess;

  RequestMiddleware get preProcess => _preProcess;
  ResponseMiddleware get postProcess => _postProcess;
  Handler get errorProcess => _errorProcess;

  final bool runAsync;
  final bool runAlways;

  // bool get useParallel => _runAsync;
  // bool get useAlways => _useAlways;

  /// Each Middleware is provided an optional [RequestMiddleware], [ResponseMiddleware],
  /// and error [Handler]. Additional parameters [runAsync] and [runAlways] determine
  /// how the Middleware will be applied to the [Pipeline].
  Middleware(
      {RequestMiddleware onRequest,
      ResponseMiddleware onResponse,
      Handler error,
      this.runAsync = false,
      this.runAlways = false}) {
    if (onRequest != null) {
      _preProcess = onRequest;
    }
    if (onResponse != null) {
      _postProcess = onResponse;
    }
    if (error != null) {
      _errorProcess = error;
    }
  }
}

// Middleware CreateMiddleware(
//     {RequestMiddleware pre,
//     ResponseMiddleware post,
//     Handler error,
//     bool useParallel: false,
//     useAlways: false}) {
//   return Middleware(
//       pre: pre,
//       post: post,
//       error: error,
//       useParallel: useParallel,
//       useAlways: useAlways);
// }
