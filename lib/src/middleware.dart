import 'package:arrow/src/handler.dart';
import 'package:arrow/src/request_middleware.dart';
import 'package:arrow/src/response_middleware.dart';

/// A process performed on a [Request] before a [Handler] (a [RequestMiddleware]) and/or on a [Response]
/// after a [Handler] (a [ResponseMiddleware]). 
/// 
/// A [Handler] can also be provided in case of an error in the Middleware execution.
/// 
/// [Middleware] is added to a [Request]/[Response] [Pipeline] and can be synchronous
/// where [useParallel] is false or asynchronous where [useParallel] is [true]. Middleware
/// can be forced to run when [useAlways] is set to [true]; this is helpful for Middleware
/// such as loggers, which should always run regardles of the Request/Response status.
/// 
/// Middleware are executed in the following order:
/// 1. Synchronous [RequestMiddleware] in the order they are added to the [Router]
/// 2. Asynchronous [RequestMiddleware] asynchronously until they are all completed
/// 3. The request [Handler] which initiates the response
/// 4. Asynchronous [ResponseMiddleware] asynchronously until they are all completed
/// 5. Synchronous [ResponseMiddleware] in the reverse order they are added to the [Router]
/// 
/// Synchronous Middleware are not guaranteed to run if a prior Middleware aborts the
/// Request/Response and [useAlways] is false. Asynchronous Middleware are not guaranteed
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

  bool _useParallel = false;
  bool _useAlways = false;

  bool get useParallel => _useParallel;
  bool get useAlways => _useAlways;

/// Each Middleware is provided an optional [RequestMiddleware], [ResponseMiddleware],
/// and error [Handler]. Additional parameters [useParallel] and [useAlways] determine
/// how the Middleware will be applied to the [Pipeline].
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
