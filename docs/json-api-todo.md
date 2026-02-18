# Arrow JSON API Todo

Remaining work to make Arrow a production-ready JSON REST API framework. No scope creep — no streaming, WebSockets, or flexible response types.

---

## Production Features

### Request Timeouts
Prevents a slow handler from holding a connection forever. Configurable per-route or global.

### Graceful Shutdown
Signal handling (SIGTERM, SIGINT) + drain in-flight requests. Required for containerized deployments (Kubernetes, Cloud Run, etc.).

---

## Architecture Cleanup

### Simplify middleware short-circuit pattern
Currently requires 3 coordinated steps that are easy to get wrong:
```dart
req.cancel();
req.respond.badRequest();
return req;
```
Forget `cancel()` → pipeline continues. Forget the response → 500. Should be a single operation.

### Remove or simplify async middleware
The sync/async middleware split is unusual and potentially dangerous. Async middleware runs concurrently with no guaranteed order — most frameworks run middleware in registration order. Consider removing `runAsync: true` entirely and running all middleware sequentially. The theoretical benefit (concurrent pre-handler work) doesn't justify the surprising behavior and ordering bugs it can introduce.

### Clean up dead code in Responder
~40 lines of commented-out redirect/complete/_onlyOnce methods from an incomplete earlier refactoring. Delete them.

### Rename `_errorResponse` or fix its signature
`_errorResponse` returns `Request`, not `Response`. It writes the error to the HTTP response, cancels the request, and returns the request object. The caller wraps it in `Response()`. The naming and flow are confusing — either rename to `_writeErrorAndCancel` or restructure to return `Response`.

---

## Production Gaps

### File upload streaming option
Uploads are fully in-memory. 50MB `maxTotalSize` default = 50MB RAM per concurrent upload. Consider an option to stream large files to a temp directory.

### Distributed rate limit store
Rate limiter is in-memory only. Can't scale horizontally. Add a `RateLimitStore` interface (already exists as abstract class) with a Redis or external implementation example.

### Request correlation IDs
No way to trace requests through logs. Add an optional middleware or built-in header (`X-Request-ID`) that propagates through the logger and context.

### Update SDK constraint
`>=2.12.0 <4.0.0` locks out Dart 3 features (records, patterns, sealed classes) that would meaningfully improve the API. Bump to `>=3.0.0 <4.0.0`.

---

## Priority Order

1. Clean up dead code in Responder (5 min, zero risk)
2. Rename `_errorResponse` (small, improves readability)
3. Remove async middleware (breaking, but removes footgun)
4. Simplify middleware short-circuit (design work needed)
5. Update SDK constraint (breaking, enables better code)
6. Request timeouts (new feature, small scope)
7. Graceful shutdown (new feature, moderate scope)
8. Request correlation IDs (small feature)
9. Distributed rate limit store (interface exists, needs example impl)
10. File upload streaming (nice-to-have, not 80% case)
