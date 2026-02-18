# Claude Code Instructions for Arrow Framework

This file contains instructions and context for Claude Code when working on the Arrow framework.

## Project Overview

Arrow is an opinionated, Express-inspired Dart server framework for rapid REST API development. It's designed for the 80-90% use case where you need a standard JSON REST API with minimal boilerplate.

**Current Status**: Architecture cleanup complete. ~85-90% feature-complete compared to modern frameworks (Express, Hono, Gin, Echo). 327 passing tests.

**Active Development**: Following a 12-week modernization plan. See `docs/modernization-plan.md` for details.

## Repository Structure

This is a git submodule within the `dart` monorepo workspace:
- Parent repo: `dart` (wrapper/workspace for Dart packages)
- This repo: `arrow` (the core framework)
- Sibling: `arrow_example` (example applications)

## Branch Strategy

**Active Branches:**
- `main` - Stable, production-ready code (GitHub default branch)
- `dev` - Active development branch with latest features

**Workflow:**
1. Work on `dev` branch for all modernization tasks
2. Create short-lived feature branches from `dev` for each task:
   - Naming: `feature/<task-name>` (e.g., `feature/file-uploads`)
   - Lifespan: 1-5 days maximum
   - Scope: Single task from modernization plan
3. Merge feature branches back to `dev` quickly
4. Merge `dev` → `main` periodically for stable releases

**Parked Branches** (future consideration):
- `parked/mcp-generator` - MCP server generation package
- `parked/openapi-codegen` - OpenAPI spec → Dart code generation
- `parked/openapi-spec-generator` - Dart code → OpenAPI spec generation

## Development Principles

1. **Test as we develop** - Write tests alongside features, not after
2. **Document as we develop** - Add Dart docs and guides with each feature
3. **Build on existing code** - Extend and improve rather than replace
4. **Stay opinionated** - Maintain Arrow's 80-90% use case focus

## Key Files

- `docs/modernization-plan.md` - 12-week plan for bringing Arrow to feature parity
- `docs/assessment.md` - Framework assessment and current state
- `docs/http-server-testing-solution.md` - Testing infrastructure notes
- `README.md` - Main project documentation

## Git Workflow Notes

- **Always work from `dev` branch** unless explicitly instructed otherwise
- **Feature branches should be atomic** - one task from the plan per branch
- **Commit frequently** with clear messages
- **Don't force push** without explicit user permission

## Testing

- Run tests: `dart test` (uses `dart_test.yaml` with `concurrency: 1`)
- Write tests alongside each feature
- Test helpers in `test/test_helpers.dart` — uses real HTTP round-trips via `createMockHttpRequest`
- Target: >80% code coverage

## What's Out of Scope

These are intentionally excluded from core framework:
- Template rendering (API-focused framework)
- Database integrations (user choice)
- ORM/query builders (user choice)
- GraphQL support (separate package)
- OpenAPI generation (separate `arrow_openapi` package)
- MCP server generation (separate `arrow_mcp_generator` package)

---

# Arrow Framework API Reference

Use this section when building applications with Arrow.

## Setup
```yaml
# pubspec.yaml
dependencies:
  arrow:
    git:
      url: https://github.com/kirklink/arrow
      ref: dev
```

## App Bootstrap
```dart
import 'package:arrow/arrow.dart';
import 'package:arrow/middlewares.dart';

void main() {
  Arrow().run(createRouter,
    port: 8080,
    printRoutes: true,
    requestTimeout: Duration(seconds: 30), // optional, no timeout by default
  );
}

Router createRouter() {
  final router = Router();
  // register middleware, routes, groups, static mounts
  return router;
}
```

## Routing
```dart
router.get('/path', handler);
router.post('/path', handler);
router.put('/path', handler);
router.delete('/path', handler);
router.patch('/path', handler);
router.head('/path', handler);

// Path params use {name} syntax
router.get('/users/{id}', (Request req) async {
  final id = req.params.get('id'); // String?
  return req.respond.ok(data: {'id': id});
});

// Groups share a prefix and middleware
final api = router.group('/api/v1');
api.get('/items', listItems);
```

## Handler Signature
```dart
typedef Future<Response> Handler(Request req);
```

## Response Methods (via req.respond)

Arrow enforces a standard JSON envelope: `{"ok": true/false, "data": ..., "errorMessage": ..., "errors": ...}`

```dart
// Success
req.respond.ok(data: {'key': 'value'})           // 200
req.respond.created(data: {'id': 1})             // 201
req.respond.code(204)                             // status only, no body
req.respond.raw(200, {'custom': 'shape'})         // bypass envelope

// Errors
req.respond.badRequest(msg: '...', errors: {...})    // 400
req.respond.unauthorized(msg: '...')                  // 401
req.respond.forbidden(msg: '...')                     // 403
req.respond.notFound(msg: '...')                      // 404
req.respond.tooManyRequests(msg: '...')               // 429
req.respond.serverError()                             // 500
req.respond.error(422, msg: '...')                    // custom code

// Files
await req.respond.sendFile(File('path/to/file'));

// Cookies (chainable — call before terminal response method)
req.respond.setCookie('name', 'value', httpOnly: true).ok(data: {...});
req.respond.clearCookie('name').ok(data: {...});
```

## Request API
```dart
req.method                          // String: 'GET', 'POST', etc.
req.uri                             // Uri
req.headers                         // HttpHeaders
req.params.get('name')              // String? - path parameter
req.content?.map                    // Map<String, Object> - parsed JSON body
req.content?.list                   // List - parsed JSON array body
req.content?.string                 // String - raw JSON string
req.queryParam('key')               // String?
req.queryParams('key')              // List<String>
req.queryInt('key')                 // int?
req.queryBool('key')                // bool?
req.cookies                         // Map<String, String>
req.cookie('name')                  // String?
req.context                         // Context (key-value store)
req.cancel()                        // stop pipeline processing
req.isAlive                         // bool
```

## Request Context
```dart
// Define a key (top-level, once)
final myKey = Context.makeKey();

// Set in middleware
req.context.setOrReplace<MyType>(myKey, value);

// Read in handler
final value = req.context.tryGet<MyType>(myKey);
```

## Middleware

### Typedefs
```dart
typedef Future<Request> RequestMiddleware(Request req);
typedef Future<Response> ResponseMiddleware(Response res);
```

### Registration
```dart
router.onRequest(myMiddleware());                            // all routes, sequential
router.onRequest(myMiddleware(), useAlways: true);            // runs even if cancelled
router.onResponse(myResponseMiddleware());

// Per-route
router.post('/upload', handler)
  ..addOnRequest(readMultipartContent());
```

### Built-in Middleware
```dart
readJsonContent()                        // parses JSON body → req.content
readMultipartContent([MultipartConfig])  // parses multipart → MultipartFormData.of(req)
enforceJsonContentType()                 // validates Content-Type by HTTP method
cors(CorsConfig(...))                    // CORS headers + preflight
securityHeaders([SecurityHeadersConfig]) // Helmet-style security headers
rateLimit([RateLimitConfig])             // IP-based fixed-window rate limiting
requestId()                              // X-Request-ID correlation (generates or echoes)
loggerIn()                               // request logger (start)
loggerOut()                              // response logger (end)
```

### Writing Custom Middleware
```dart
RequestMiddleware requireAuth() {
  return (Request req) async {
    final token = req.headers.value('authorization');
    if (token == null) {
      req.respond.unauthorized(msg: 'Auth required'); // auto-cancels pipeline
      return req;
    }
    return req;
  };
}
```

## HttpException (throw from handlers/middleware)
```dart
throw BadRequestException('Invalid input', {'field': 'reason'});
throw UnauthorizedException();
throw ForbiddenException();
throw NotFoundException('User not found');
throw ConflictException();
throw TooManyRequestsException();
throw InternalServerException();
// Auto-caught by router → standard error JSON response
```

## File Uploads
```dart
router.onRequest(readMultipartContent(MultipartConfig(
  maxFileSize: 5 * 1024 * 1024,      // per file, default 10MB
  maxTotalSize: 50 * 1024 * 1024,     // all files, default 50MB
  maxFiles: 10,                        // default 10
  allowedMimeTypes: ['image/png'],     // empty = all
)));

// In handler:
final form = MultipartFormData.of(req)!;
form.field('name')                     // String?
form.file('avatar')                    // UploadedFile? (.fieldName, .filename, .contentType, .bytes, .size)
form.filesFor('photos')                // List<UploadedFile>
```

## Static Files
```dart
router.serveStaticFiles('/public', 'web/public', StaticFilesConfig(
  index: 'index.html',   // default
  maxAge: 3600,           // seconds, default
  etag: true,             // default
  headers: {},            // extra headers
));
```

## Gotchas
- `req.content` is null until `readJsonContent()` middleware runs
- Error response methods (`badRequest()`, `unauthorized()`, etc.) auto-cancel the pipeline — no need to call `req.cancel()` separately
- `cancel()` stops the pipeline — middleware with `useAlways: true` still runs
- Response is JSON-only (no HTML/template rendering)
- Context keys must be created via `Context.makeKey()` (UUID strings)
- Middleware execution order: request middleware (sequential) → handler → response middleware (sequential)
- SDK constraint: `>=3.0.0 <4.0.0` — Dart 3 features (records, patterns, sealed) available
