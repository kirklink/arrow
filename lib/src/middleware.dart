// import 'handler.dart';
// import 'request_middleware.dart';
// import 'response_middleware.dart';

// /// A process performed on a [Request] before a [Handler] (a [RequestMiddleware]) and/or on a [Response]
// /// after a [Handler] (a [ResponseMiddleware]).
// ///
// /// A [Handler] can also be provided in case of an error in the Middleware execution.
// ///
// /// [Middleware] is added to a [Request]/[Response] [Pipeline] and can be synchronous
// /// where [runAsync] is false or asynchronous where [runAsync] is true. Middleware
// /// can be forced to run when [useAlways] is set to true; this is helpful for Middleware
// /// such as loggers, which should always run regardles of the Request/Response status.
// ///

// ///
// /// Synchronous Middleware are not guaranteed to run if a prior Middleware aborts the
// /// Request/Response and [useAlways] is false. Asynchronous Middleware are not guaranteed
// /// to run if a sibling asynchronous Middleware finishes first and aborts the Request/Response.
// /// Asynchronous Middleware may complete in any order so they should be used carefully;
// /// generally not to modify the Request/Response if other asynchronous Middleware depend
// /// on the modification or to spawn related but independent processes such as storing a request
// /// count to a database or retrieving multiple services a handler might depend on.
// class Middleware {
//   RequestMiddleware _requestMiddleware;
//   ResponseMiddleware _responseMiddleware;
//   Handler _errorHandler;

//   RequestMiddleware get requestMiddleware => _requestMiddleware;
//   ResponseMiddleware get responseMiddleware => _responseMiddleware;
//   Handler get errorHandler => _errorHandler;

//   final bool runAsync;
//   final bool useAlways;

//   // bool get useParallel => _runAsync;
//   // bool get useAlways => _useAlways;

//   /// Each Middleware is provided an optional [RequestMiddleware], [ResponseMiddleware],
//   /// and error [Handler]. Additional parameters [runAsync] and [useAlways] determine
//   /// how the Middleware will be applied to the [Pipeline].
//   Middleware(
//       {RequestMiddleware onRequest,
//       ResponseMiddleware onResponse,
//       Handler error,
//       this.runAsync = false,
//       this.useAlways = false}) {
//     if (onRequest != null) {
//       _requestMiddleware = onRequest;
//     }
//     if (onResponse != null) {
//       _responseMiddleware = onResponse;
//     }
//     if (error != null) {
//       _errorHandler = error;
//     }
//   }
// }

// // Middleware CreateMiddleware(
// //     {RequestMiddleware pre,
// //     ResponseMiddleware post,
// //     Handler error,
// //     bool useParallel: false,
// //     useAlways: false}) {
// //   return Middleware(
// //       pre: pre,
// //       post: post,
// //       error: error,
// //       useParallel: useParallel,
// //       useAlways: useAlways);
// // }
