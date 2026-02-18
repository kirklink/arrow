import 'package:uuid/uuid.dart';

import 'package:arrow/src/request.dart';
import 'package:arrow/src/request_middleware.dart';
import 'package:arrow/src/context.dart';

/// Context key for the request ID. Use with `req.context.tryGet<String>(requestIdKey)`.
final requestIdKey = Context.makeKey();

const _headerName = 'X-Request-ID';
final _uuid = Uuid();

/// Request middleware that assigns a correlation ID to each request.
///
/// If the client sends an `X-Request-ID` header, that value is used.
/// Otherwise a new UUID v4 is generated.
///
/// The ID is:
/// - Stored in the request context under [requestIdKey]
/// - Set as the `X-Request-ID` response header
///
/// ```dart
/// router.onRequest(requestId());
///
/// // In a handler:
/// final id = req.context.tryGet<String>(requestIdKey);
/// ```
RequestMiddleware requestId() {
  return _requestId;
}

Future<Request> _requestId(Request req) async {
  final existing = req.headers.value(_headerName);
  final id = (existing != null && existing.isNotEmpty) ? existing : _uuid.v4();
  req.context.setOrReplace<String>(requestIdKey, id);
  // Set the response header now, before the handler writes the body
  // (response headers become immutable after write).
  req.innerRequest.response.headers.set(_headerName, id);
  return req;
}
