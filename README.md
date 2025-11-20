# Arrow

An opinionated, Express-inspired Dart server framework for rapid REST API development.

[![Dart](https://img.shields.io/badge/dart-%3E%3D2.12.0-blue.svg)](https://dart.dev)
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
req.respond.ok(data: {'user': 'Alice'});           // 200 OK (GET)
req.respond.ok(data: {'id': 123});                 // 201 Created (POST)
req.respond.code(204);                             // 204 No Content

// Error responses
req.respond.badRequest(msg: 'Invalid input');      // 400
req.respond.unauthorized(msg: 'Login required');   // 401
req.respond.forbidden(msg: 'Access denied');       // 403
req.respond.notFound(msg: 'Resource not found');   // 404
req.respond.serverError();                         // 500

// Custom responses
req.respond.raw(418, {'message': "I'm a teapot"});
```

### Middleware

Middleware functions run before/after handlers to add cross-cutting concerns:

```dart
import 'package:arrow/middlewares.dart';

final router = Router();

// Add middleware to all routes
router.use(cors());
router.use(logger());

// Middleware for specific route groups
final apiRouter = router.group('/api');
apiRouter.use(requireAuth());
apiRouter.get('/users', getUsers);
```

#### Built-in Middleware

- **cors()** - Cross-Origin Resource Sharing
- **logger()** - Request logging
- **readJsonContent()** - Parse JSON request bodies
- **enforceJsonContentType()** - Require `Content-Type: application/json`

#### Custom Middleware

```dart
// Request middleware (runs before handler)
RequestMiddleware authMiddleware() {
  return (Request req) async {
    final token = req.headers.value('authorization');

    if (token == null) {
      req.cancel();
      return req.respond.unauthorized(msg: 'Missing auth token');
    }

    final user = await validateToken(token);
    req.context.setOrReplace('user', user);

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
// In middleware
RequestMiddleware loadUser() {
  return (Request req) async {
    final userId = req.params.get('userId');
    final user = await database.findUser(userId);

    req.context.setOrReplace('user', user);
    return req;
  };
}

// In handler
Response getProfile(Request req) {
  final user = req.context.tryGet<User>('user');

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
v1.use(apiKeyAuth());

v1.get('/users', getAllUsers);
v1.post('/users', createUser);

// Admin routes with additional auth
final admin = v1.group('/admin');
admin.use(requireAdmin());
admin.get('/stats', getStats);
admin.delete('/users/{id}', deleteUser);
```

### Request Cancellation

Cancel request processing in middleware to short-circuit:

```dart
RequestMiddleware requireAuth() {
  return (Request req) async {
    final token = req.headers.value('authorization');

    if (token == null) {
      req.cancel();  // Stop processing
      return req.respond.unauthorized(msg: 'Auth required');
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

void main() async {
  final app = Arrow();

  await app.run(() {
    final router = Router();

    // Global middleware
    router.use(cors());
    router.use(logger());

    // Public routes
    router.get('/health', healthCheck);

    // API routes with auth
    final api = router.group('/api');
    api.use(readJsonContent());
    api.use(requireAuth());

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
  }, port: 8080, printRoutes: true);
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
  // Your implementation
  return req.respond.ok(data: {'id': id});
}

Future<Response> createUser(Request req) async {
  // Your implementation
  return req.respond.ok(data: {'created': true});
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

RequestMiddleware requireAuth() {
  return (Request req) async {
    final token = req.headers.value('authorization');

    if (token == null || token.isEmpty) {
      req.cancel();
      return req.respond.unauthorized(msg: 'Authentication required');
    }

    // Validate token and load user
    // req.context.setOrReplace('user', user);

    return req;
  };
}
```

## Middleware Execution Order

Arrow executes middleware in a specific, predictable order:

1. **Sync Request Middleware** - Sequential, in order added
2. **Async Request Middleware** - Parallel execution, waits for all
3. **Handler** - Your route handler
4. **Async Response Middleware** - Parallel execution, waits for all
5. **Sync Response Middleware** - Sequential, in order added

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
  port: 8080,              // Default port (overridden by ARROW_PORT)
  forceSSL: false,         // Redirect HTTP to HTTPS
  printRoutes: true,       // Print all routes on startup
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
**Status:** Active development

### Recently Completed
- ✅ Null-safety support
- ✅ Async middleware bug fix
- ✅ Comprehensive test suite (100 tests)
- ✅ HTTP test helpers

### Roadmap
- Request validation framework
- File upload support
- WebSocket support
- OpenAPI/Swagger generation
- Rate limiting middleware

See [docs/assessment.md](docs/assessment.md) for detailed technical assessment.

## Why Arrow?

**Use Arrow if you want:**
- Fast development of standard REST JSON APIs
- Express-like ergonomics in Dart
- Strong typing and null-safety
- Minimal boilerplate for common patterns

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
