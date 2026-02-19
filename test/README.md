# Arrow Framework Tests

This directory contains the test suite for the Arrow server framework.

## Running Tests

### Run all tests
```bash
dart test
```

### Run specific test file
```bash
dart test test/unit/context_test.dart
dart test test/unit/pipeline_simple_test.dart
```

### Run with coverage (future)
```bash
dart test --coverage=coverage
```

## Test Structure

```
test/
├── unit/                           # Unit tests for individual components
│   ├── context_test.dart           # Context class tests (17 tests)
│   ├── pipeline_simple_test.dart   # Pipeline async middleware tests (7 tests)
│   ├── request_test.dart           # Request class tests (6 tests)
│   ├── responder_test.dart         # Responder class tests (29 tests)
│   ├── parameters_test.dart        # Parameters class tests (17 tests)
│   └── internal_messenger_test.dart # InternalMessenger class tests (24 tests)
├── integration/                    # Integration tests (future)
└── test_helpers.dart               # HTTP request mocking utilities
```

## Test Coverage

### Unit Tests (100 total)

#### Context Tests (17 tests)
- ✅ setOrReplace functionality
- ✅ trySet functionality
- ✅ tryGet functionality
- ✅ getOrSet functionality
- ✅ has functionality
- ✅ tryDelete functionality
- ✅ makeKey UUID generation
- ✅ Concurrent modifications

#### Pipeline Async Middleware Tests (7 tests)
- ✅ Multiple async middleware preserve all modifications
- ✅ Old buggy behavior analysis
- ✅ Non-deterministic completion order
- ✅ Race conditions on same key
- ✅ Sync middleware sequential execution
- ✅ Correct execution order (sync → async → handler → response)
- ✅ Request cancellation with useAlways flag

#### Request Tests (6 tests)
- ✅ Request creation from HttpRequest
- ✅ Empty context initialization
- ✅ Context value setting
- ✅ Request cancellation
- ✅ HTTP headers access
- ✅ Messenger for tracking messages

#### Responder Tests (29 tests)
- ✅ ok() method with data and status codes (200 for GET, 201 for POST)
- ✅ raw() method with custom status codes
- ✅ code() method for status-only responses
- ✅ notFound() 404 responses
- ✅ unauthorized() 401 responses
- ✅ forbidden() 403 responses
- ✅ badRequest() 400 responses with validation errors
- ✅ serverError() 500 responses
- ✅ Response prevention (throws on multiple responses)

#### Parameters Tests (18 tests)
- ✅ Empty initialization
- ✅ load() method with parameter maps
- ✅ get() method returning values or null for missing
- ✅ URL-decoding of percent-encoded path parameters
- ✅ ParametersException on double-load
- ✅ Special characters and URL parameters
- ✅ REST API and slug-based routing patterns

#### InternalMessenger Tests (24 tests)
- ✅ Empty initialization
- ✅ addMessage() method
- ✅ addError() method
- ✅ Message and error independence
- ✅ Order preservation
- ✅ Duplicate handling
- ✅ Special characters support
- ✅ Request lifecycle tracking patterns

## Test Helpers

### HTTP Request Mocking

The `test_helpers.dart` library provides utilities for creating mock HTTP requests without deadlocks.

**Import:**
```dart
import '../test_helpers.dart';
```

**Basic Usage:**
```dart
test('my test', () async {
  final httpReq = await createMockHttpRequest();
  final req = Request(httpReq);
  // Use req in your test
  await cleanupMockRequest(httpReq);
});
```

**With Custom Method and Body:**
```dart
final httpReq = await createMockHttpRequest(
  path: '/api/users',
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: '{"name": "Alice"}',
);
```

**Convenience Methods:**
```dart
// GET request
final req = await createMockGetRequest(path: '/users');

// POST with JSON
final req = await createMockPostRequest(
  path: '/users',
  body: '{"name": "Alice"}',
);

// PUT with JSON
final req = await createMockPutRequest(
  path: '/users/1',
  body: '{"name": "Bob"}',
);

// DELETE
final req = await createMockDeleteRequest(path: '/users/1');

// PATCH with JSON
final req = await createMockPatchRequest(
  path: '/users/1',
  body: '{"age": 30}',
);
```

**Cleanup:**
```dart
group('MyTests', () {
  tearDownAll(() async {
    await cleanupAllMockRequests();  // Clean up all servers
  });

  test('individual cleanup', () async {
    final req = await createMockHttpRequest();
    // ...
    await cleanupMockRequest(req);  // Clean up one server
  });
});
```

### Why Not `server.first`?

❌ **DO NOT use `await server.first`** - it causes deadlocks:
```dart
// This deadlocks!
final server = await HttpServer.bind('localhost', 0);
final request = await client.get('localhost', server.port, '/');
final serverReq = await server.first;  // DEADLOCK!
```

✅ **Use test helpers instead** - they use `server.listen()` with `Completer`:
```dart
// This works!
final httpReq = await createMockHttpRequest();
```

See [docs/http-server-testing-solution.md](../docs/http-server-testing-solution.md) for technical details.

## Writing New Tests

### Unit Tests

Create new unit test files in `test/unit/`:

```dart
import 'package:test/test.dart';
import 'package:arrow/src/your_class.dart';

void main() {
  group('YourClass', () {
    test('should do something', () {
      // Arrange
      final obj = YourClass();

      // Act
      final result = obj.doSomething();

      // Assert
      expect(result, equals(expectedValue));
    });
  });
}
```

### Integration Tests (Future)

When HTTP server issue is resolved, create integration tests in `test/integration/`:

```dart
import 'package:test/test.dart';
import 'package:arrow/arrow.dart';

void main() {
  group('Router Integration', () {
    test('should handle GET request', () async {
      // Test full request/response cycle
    });
  });
}
```

## Test Guidelines

### DO
- ✅ Test one thing per test
- ✅ Use descriptive test names
- ✅ Use `group()` to organize related tests
- ✅ Use `setUp()` and `tearDown()` for common setup
- ✅ Test edge cases and error conditions
- ✅ Keep tests fast and isolated

### DON'T
- ❌ Create actual HTTP servers (until issue is fixed)
- ❌ Test multiple things in one test
- ❌ Depend on test execution order
- ❌ Use sleep() or arbitrary delays
- ❌ Share mutable state between tests

## CI/CD Integration (Future)

```yaml
# Example GitHub Actions workflow
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart test
```

## Test Metrics

- **Total Tests:** 100
- **Passing:** 100 (100%)
- **Coverage:** TBD (coverage tool not yet configured)

## Future Improvements

1. Add integration tests (once HTTP server issue resolved)
2. Add test coverage reporting
3. Add performance/benchmark tests
4. Add tests for Router and Response classes
5. Add tests for middleware (CORS, Logger, etc.)
6. Set up CI/CD pipeline
7. Add mutation testing
8. Add tests for error handling and edge cases in Pipeline

## Contributing

When adding new features:
1. Write tests first (TDD)
2. Ensure all tests pass: `dart test`
3. Add test documentation to this README
4. Update test metrics
