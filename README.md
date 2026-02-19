# Arrow

An opinionated, Express-inspired Dart server framework for rapid REST API development.

[![Dart](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Philosophy

Arrow is designed for the **80-90% use case** where you need a standard JSON REST API with minimal boilerplate. It trades flexibility for developer speed, providing:

- **Opinionated** - Standardized JSON response format for consistency
- **Fast Development** - Minimal boilerplate for common API patterns
- **Express/Go-inspired** - Familiar routing and middleware patterns
- **Type-Safe** - Full Dart type safety with null-safety support

## Quick Start

### Installation

Add Arrow to your `pubspec.yaml`:

```yaml
dependencies:
  arrow:
    git:
      url: https://github.com/kirklink/arrow
      ref: dev
```

### Hello World

```dart
import 'package:arrow/arrow.dart';

void main() async {
  final app = Arrow();

  await app.run(() {
    final router = Router();

    router.get('/hello', (Request req) async {
      return req.respond.ok(data: {'message': 'Hello, World!'});
    });

    return router;
  }, port: 8080);
}
```

Visit `http://localhost:8080/hello` to see:

```json
{
  "ok": true,
  "data": {
    "message": "Hello, World!"
  }
}
```

## Core Concepts

### Routing

Arrow uses Express-style routing with support for path parameters:

```dart
final router = Router();

// Basic routes
router.get('/users', getAllUsers);
router.post('/users', createUser);

// Path parameters
router.get('/users/{id}', getUserById);
router.put('/users/{id}', updateUser);
router.delete('/users/{id}', deleteUser);

// Multiple parameters
router.get('/posts/{postId}/comments/{commentId}', getComment);
```

### Handlers

Handlers receive a `Request` object and return a `Response`:

```dart
Response getUserById(Request req) {
  final id = req.params.get('id');

  // Your logic here
  final user = database.findUser(id);

  if (user == null) {
    return req.respond.notFound(msg: 'User not found');
  }

  return req.respond.ok(data: user.toJson());
}
```

### Response Methods

Arrow provides convenient response methods:

```dart
// Success responses
req.respond.ok(data: {'user': 'Alice'});           // 200 OK
req.respond.created(data: {'id': 123});            // 201 Created
req.respond.code(204);                             // 204 No Content

// Error responses
req.respond.badRequest(msg: 'Invalid input');      // 400
req.respond.unauthorized(msg: 'Login required');   // 401
req.respond.forbidden(msg: 'Access denied');       // 403
req.respond.notFound(msg: 'Resource not found');   // 404
req.respond.tooManyRequests(msg: 'Slow down');     // 429
req.respond.serverError();                         // 500

// File responses
await req.respond.sendFile(File('uploads/photo.png'));

// Cookie responses (chainable)
req.respond.setCookie('token', 'abc', httpOnly: true).ok(data: {...});
req.respond.clearCookie('token').ok(data: {...});

// Custom responses
req.respond.raw(418, {'message': "I'm a teapot"});
req.respond.error(422, msg: 'Unprocessable');
```

### Middleware

Middleware functions run before/after handlers to add cross-cutting concerns:

```dart
import 'package:arrow/middlewares.dart';

final router = Router();

// Add middleware to all routes
router.onRequest(cors(CorsConfig()));
router.onRequest(loggerIn());
router.onResponse(loggerOut());

// Middleware for specific route groups
final apiRouter = router.group('/api');
apiRouter.onRequest(readJsonContent());
apiRouter.onRequest(requireAuth());
apiRouter.get('/users', getUsers);
```

#### Built-in Middleware

- **readJsonContent()** - Parse JSON request bodies
- **readMultipartContent()** - Parse multipart/form-data file uploads
- **enforceJsonContentType()** - Require `Content-Type: application/json`
- **cors()** - Cross-Origin Resource Sharing
- **securityHeaders()** - Helmet-style security response headers (CSP, HSTS, etc.)
- **rateLimit()** - IP-based rate limiting with configurable windows
- **requestId()** - `X-Request-ID` correlation (generates UUID or echoes client header)
- **jwtAuth()** - JWT authentication with configurable key, issuer, audience
- **loggerIn()** / **loggerOut()** - Request/response logging

#### Static File Serving

Serve frontend assets, images, and downloads with built-in caching:

```dart
final router = Router();

// Serve files from 'web/public' at '/public/*'
router.serveStaticFiles('/public', 'web/public');

// With custom config
router.serveStaticFiles('/assets', 'web/assets', StaticFilesConfig(
  maxAge: 86400,       // Cache for 24 hours
  etag: true,          // ETag-based caching (default)
  index: 'index.html', // Index file for directories (default)
));
```

Static mounts are checked before route matching. Includes ETag/304 support, Cache-Control headers, Content-Type detection via `MimeType`, path traversal protection, and HEAD request support.

#### File Uploads

Parse multipart/form-data file uploads with configurable validation:

```dart
import 'package:arrow/middlewares.dart';

final router = Router();

// Apply multipart parsing middleware
router.onRequest(readMultipartContent(MultipartConfig(
  maxFileSize: 5 * 1024 * 1024,  // 5MB per file
  maxFiles: 3,
  allowedMimeTypes: ['image/jpeg', 'image/png'],
)));

router.post('/upload', (Request req) async {
  final form = MultipartFormData.of(req)!;
  final description = form.field('description');
  final photo = form.file('photo');
  // photo.filename, photo.contentType, photo.bytes, photo.size
  return req.respond.ok(data: {'uploaded': photo?.filename});
});
```

#### JWT Authentication

Arrow includes provider-agnostic JWT authentication built on [dart_jsonwebtoken](https://pub.dev/packages/dart_jsonwebtoken) (HMAC, RSA, ECDSA, EdDSA):

```dart
import 'package:arrow/jwt.dart';  // re-exports dart_jsonwebtoken types

final router = Router();

// Protect routes with JWT auth
router.onRequest(jwtAuth(JwtAuthConfig(
  key: SecretKey('my-secret'),
  issuer: 'https://auth.example.com',    // optional
  audience: 'my-api',                    // optional
)));

// Access verified JWT in handlers
router.get('/me', (Request req) async {
  final jwt = getJwt(req)!;
  return req.respond.ok(data: {'userId': jwt.payload['sub']});
});

// Sign tokens in login handlers (unprotected route)
router.post('/login', (Request req) async {
  // ... validate credentials ...
  final jwt = JWT({'sub': user.id, 'role': user.role});
  final token = jwt.sign(SecretKey('my-secret'), expiresIn: Duration(hours: 1));
  return req.respond.ok(data: {'token': token});
});
```

`jwt.dart` re-exports all key types (`JWT`, `SecretKey`, `RSAPublicKey`, `ECPublicKey`, `EdDSAPublicKey`, etc.) so you don't need `dart_jsonwebtoken` as a direct dependency.

#### Custom Middleware

```dart
// Request middleware (runs before handler)
RequestMiddleware requireRole(String role) {
  return (Request req) async {
    final jwt = getJwt(req);
    if (jwt == null || jwt.payload['role'] != role) {
      req.respond.forbidden(msg: 'Insufficient permissions');
      return req;
    }
    return req;
  };
}

// Response middleware (runs after handler)
ResponseMiddleware timingMiddleware() {
  return (Response res) async {
    res.request.messenger.addMessage('Request completed');
    return res;
  };
}
```

### Request Context

Share data between middleware and handlers using the request context:

```dart
// Define a key (top-level, once)
final userKey = Context.makeKey();

// In middleware
RequestMiddleware loadUser() {
  return (Request req) async {
    final userId = req.params.get('userId');
    final user = await database.findUser(userId);
    req.context.setOrReplace<User>(userKey, user);
    return req;
  };
}

// In handler
Response getProfile(Request req) {
  final user = req.context.tryGet<User>(userKey);

  if (user == null) {
    return req.respond.notFound(msg: 'User not found');
  }

  return req.respond.ok(data: user.toJson());
}
```

### Router Groups

Organize routes with shared paths and middleware:

```dart
final router = Router();

// API v1 routes
final v1 = router.group('/api/v1');
v1.onRequest(apiKeyAuth());

v1.get('/users', getAllUsers);
v1.post('/users', createUser);

// Admin routes with additional auth
final admin = v1.group('/admin');
admin.onRequest(requireAdmin());
admin.get('/stats', getStats);
admin.delete('/users/{id}', deleteUser);
```

### Middleware Short-Circuit

Error response methods (`badRequest()`, `unauthorized()`, etc.) automatically cancel the request pipeline. No need to call `cancel()` separately:

```dart
RequestMiddleware requireAuth() {
  return (Request req) async {
    final token = req.headers.value('authorization');

    if (token == null) {
      req.respond.unauthorized(msg: 'Auth required');  // cancels pipeline
      return req;
    }

    return req;
  };
}
```

### Router Configuration with Cascade Operator

Dart's cascade operator (`..`) enables elegant fluent configuration in a separate file:

```dart
// router_config.dart
import 'package:arrow/arrow.dart';
import 'package:arrow/middlewares.dart';

Router routerConfig() {
  Future<Response> notFoundHandler(Request req) async {
    return req.respond.notFound(msg: 'Endpoint not found');
  }

  return Router()
    ..notFound(notFoundHandler)
    ..onRequest(loggerIn(), useAlways: true)
    ..onResponse(loggerOut(messages: true), useAlways: true)
    ..get('/health', healthCheck)
    ..get('/users', getAllUsers)
    ..get('/users/{id}', getUserById)
    ..post('/users', createUser)
    ..put('/users/{id}', updateUser)
    ..delete('/users/{id}', deleteUser);
}

// main.dart
import 'router_config.dart';

void main() async {
  final app = Arrow();
  await app.run(routerConfig, port: 8080);
}
```

The cascade operator (`..`) calls methods on the same object and returns the object, making it perfect for configuring routers in a clean, chainable style.

## Production Features

### Request Timeouts

Prevent hanging requests with a configurable global timeout:

```dart
await app.run(routerConfig,
  port: 8080,
  requestTimeout: Duration(seconds: 30),
);
```

When a request exceeds the timeout, Arrow responds with a 408 status and standard JSON error envelope.

### Graceful Shutdown

Arrow handles SIGINT and SIGTERM signals automatically:

```dart
await app.run(routerConfig,
  port: 8080,
  shutdownTimeout: Duration(seconds: 30), // drain period for in-flight requests
);
```

During shutdown:
1. New requests receive 503 Service Unavailable
2. In-flight requests are allowed to complete within the shutdown timeout
3. Server closes cleanly after all requests drain (or timeout expires)

### Request ID Correlation

Track requests across services with `X-Request-ID`:

```dart
router.onRequest(requestId());
```

Generates a UUID v4 for each request, or echoes the client-provided `X-Request-ID` header. The ID is stored in the request context and set on the response.

## MCP Code Generation

Arrow includes annotation-driven MCP (Model Context Protocol) server code generation. Write the Arrow endpoint, get the MCP tooling for free.

```dart
// lib/user_service_mcp.dart
import 'package:arrow/mcp.dart';

@McpServer('user-api', description: 'User management API')
class UserServiceMcp {
  @McpTool(description: 'Get all users', method: 'GET', path: '/users')
  final getUsers = null;

  @McpTool(
    description: 'Get user by ID',
    method: 'GET',
    path: '/users/{id}',
    parameters: {'id': 'The unique user identifier'},
  )
  final getUser = null;
}
```

Run `dart run build_runner build` to generate a `.mcp.dart` file with:
- Const `McpToolDefinition` for each annotated tool
- A typed tool list for static registration
- An `McpDispatcher` subclass that proxies MCP tool calls as HTTP requests to your Arrow server

See [arrow_mcp_builder/](arrow_mcp_builder/) for setup instructions.

## Response Format

Arrow uses a consistent JSON response format:

**Success Response:**
```json
{
  "ok": true,
  "data": {
    "user": "Alice",
    "email": "alice@example.com"
  }
}
```

**Error Response:**
```json
{
  "ok": false,
  "errorMessage": "User not found",
  "errors": {
    "userId": "Invalid user ID format"
  }
}
```

## Complete Example

```dart
import 'package:arrow/arrow.dart';
import 'package:arrow/middlewares.dart';
import 'package:arrow/jwt.dart';

void main() async {
  final app = Arrow();

  await app.run(() {
    final router = Router();

    // Global middleware
    router.onRequest(requestId());
    router.onRequest(cors(CorsConfig()));
    router.onRequest(loggerIn(), useAlways: true);
    router.onResponse(loggerOut(), useAlways: true);

    // Public routes
    router.get('/health', healthCheck);

    // API routes with JWT auth
    final api = router.group('/api');
    api.onRequest(readJsonContent());
    api.onRequest(jwtAuth(JwtAuthConfig(
      key: SecretKey('my-secret'),
    )));

    // User routes
    api.get('/users', getAllUsers);
    api.get('/users/{id}', getUserById);
    api.post('/users', createUser);
    api.put('/users/{id}', updateUser);
    api.delete('/users/{id}', deleteUser);

    // Not found handler
    router.notFound((Request req) async {
      return req.respond.notFound(msg: 'Endpoint not found');
    });

    return router;
  },
    port: 8080,
    printRoutes: true,
    requestTimeout: Duration(seconds: 30),
  );
}

Future<Response> healthCheck(Request req) async {
  return req.respond.ok(data: {'status': 'healthy'});
}

Future<Response> getAllUsers(Request req) async {
  // Your implementation
  return req.respond.ok(data: {'users': []});
}

Future<Response> getUserById(Request req) async {
  final id = req.params.get('id');
  final jwt = getJwt(req)!; // verified JWT from middleware
  return req.respond.ok(data: {'id': id, 'requestedBy': jwt.payload['sub']});
}

Future<Response> createUser(Request req) async {
  // Your implementation
  return req.respond.created(data: {'id': 1});
}

Future<Response> updateUser(Request req) async {
  final id = req.params.get('id');
  // Your implementation
  return req.respond.ok(data: {'id': id, 'updated': true});
}

Future<Response> deleteUser(Request req) async {
  final id = req.params.get('id');
  // Your implementation
  return req.respond.code(204);
}
```

## Middleware Execution Order

All middleware runs sequentially in the order it was registered:

1. **Request Middleware** - Sequential, in order added
2. **Handler** - Your route handler
3. **Response Middleware** - Sequential, in order added

## HTTP Methods

Supported HTTP methods:

- `router.get(path, handler)`
- `router.post(path, handler)`
- `router.put(path, handler)`
- `router.delete(path, handler)`
- `router.patch(path, handler)`
- `router.head(path, handler)`

## Configuration

### Environment Variables

- `ARROW_PORT` - Override the port (takes precedence over code)
- `BUILD_ENV` - Set environment: `production`, `staging`, `development`

### Server Options

```dart
await app.run(
  routerBuilder,
  port: 8080,                                  // Default port (overridden by ARROW_PORT)
  forceSSL: false,                             // Redirect HTTP to HTTPS
  printRoutes: true,                           // Print all routes on startup
  requestTimeout: Duration(seconds: 30),       // Global request timeout (optional)
  shutdownTimeout: Duration(seconds: 30),      // Graceful shutdown drain period
);
```

## Testing

Arrow includes comprehensive test coverage. Run tests with:

```bash
dart test
```

See [test/README.md](test/README.md) for testing documentation.

## Project Status

**Current Version:** 0.1.0-nullsafety.0
**Status:** Active development — 381 passing tests

### Features
- All HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD)
- Path parameters and query parameter helpers with type coercion
- HttpException hierarchy for structured error handling
- Cookie support (reading and chainable writing)
- Security headers middleware (Helmet-style)
- Rate limiting middleware (fixed window, configurable)
- Response compression (gzip via `autoCompress`)
- Static file serving with ETag caching and MimeType detection
- File upload support (multipart/form-data with validation)
- Request timeouts (configurable per-server)
- Graceful shutdown (SIGINT/SIGTERM, in-flight drain)
- Request ID correlation (X-Request-ID)
- JWT authentication (provider-agnostic, 14 algorithms via dart_jsonwebtoken)
- MCP code generation with HTTP transport proxy

### Roadmap
- Flexible response types (non-JSON)
- Streaming responses / SSE
- WebSocket support

See [docs/modernization-plan.md](docs/modernization-plan.md) for the full roadmap.

## Why Arrow?

**Use Arrow if you want:**
- Fast development of standard REST JSON APIs
- Express-like ergonomics in Dart
- Strong typing and null-safety
- Minimal boilerplate for common patterns
- AI-ready with built-in MCP code generation

**Don't use Arrow if you need:**
- Complete flexibility in response formats
- GraphQL or other non-REST patterns
- Complex custom middleware pipelines
- HTML rendering or server-side templates

## Contributing

Contributions are welcome! Please:

1. Run tests: `dart test`
2. Follow existing code style
3. Add tests for new features
4. Update documentation

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Comparison to Alternatives

- **vs. Shelf** - More opinionated, faster for common cases, less flexible
- **vs. Serverpod** - Lightweight, API-only, no ORM or real-time features
- **vs. Express.js** - Similar API, Dart performance, smaller ecosystem

Arrow is designed for developers who want Express-like ergonomics with Dart's performance and type safety, specifically for building JSON REST APIs.
