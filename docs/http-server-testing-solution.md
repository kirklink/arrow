# HTTP Server Testing Solution

**Date:** 2025-11-20
**Status:** ✅ Solved

## Problem

Tests that created HTTP servers using `HttpServer.bind()` were causing 30-second timeouts and crashes.

**Original failing pattern:**
```dart
Future<HttpRequest> _createMockRequest() async {
  final server = await HttpServer.bind('localhost', 0);
  final client = HttpClient();
  final request = await client.get('localhost', server.port, '/test');
  final response = await request.close();
  final serverRequest = await server.first;  // ❌ DEADLOCK!
  // ...
}
```

## Root Cause

**Deadlock with `server.first`:**

1. Client makes HTTP request and awaits response
2. `await server.first` tries to get the request from the server
3. Both are waiting for each other → DEADLOCK

**Why it deadlocks:**
- `client.get()` sends the request but blocks waiting for response
- `server.first` blocks waiting to receive the request
- Neither can proceed because they're both waiting

## Solution

Use `server.listen()` with a `Completer` instead of `server.first`:

```dart
Future<HttpRequest> createMockHttpRequest({String path = '/test'}) async {
  final server = await HttpServer.bind('localhost', 0);
  final port = server.port;

  // Use a Completer to capture the request
  final completer = Completer<HttpRequest>();

  // Set up listener BEFORE making the request
  late StreamSubscription subscription;
  subscription = server.listen((request) {
    if (!completer.isCompleted) {
      completer.complete(request);
      subscription.cancel();
    }
  });

  // Make the client request in the background (non-blocking)
  final client = HttpClient();
  client.get('localhost', port, path).then((request) {
    return request.close();
  }).then((response) {
    response.drain(); // Consume response
  }).whenComplete(() {
    client.close();
  });

  // Wait for and return the server request
  return completer.future;
}
```

**Key differences:**
1. ✅ Use `server.listen()` instead of `server.first`
2. ✅ Use `Completer` to capture the request asynchronously
3. ✅ Make client request with `.then()` instead of `await`
4. ✅ No deadlock - server listener is ready before client sends

## Implementation

### Test Helper

Created `test/test_helpers.dart` with reusable mock request creation:

```dart
/// Creates a mock HttpRequest for testing without deadlocks
Future<HttpRequest> createMockHttpRequest({String path = '/test'})

/// Clean up the server associated with a mock request
Future<void> cleanupMockRequest(HttpRequest request)

/// Clean up all mock request servers
Future<void> cleanupAllMockRequests()
```

### Usage in Tests

```dart
import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import '../test_helpers.dart';

void main() {
  group('Request', () {
    tearDownAll(() async {
      await cleanupAllMockRequests();
    });

    test('should be created from HttpRequest', () async {
      final mockHttpRequest = await createMockHttpRequest();
      final request = Request(mockHttpRequest);

      expect(request.method, equals('GET'));

      await cleanupMockRequest(mockHttpRequest);
    });
  });
}
```

## Test Results

**Before fix:**
```
00:30 +0 -1: Pipeline tests [E]
  TimeoutException after 0:00:30.000000
```

**After fix:**
```
00:01 +6: All tests passed!
```

✅ All 6 Request tests pass without timeouts
✅ Execution time: <1 second (vs 30+ second timeout)

## Files Created

1. **`test/test_helpers.dart`** - Reusable mock HTTP request helpers
2. **`test/unit/request_test.dart`** - Request class tests using helpers
3. **`test/debug_http_server.dart`** - Debug script (can be deleted)
4. **`test/debug_http_server2.dart`** - Debug script (can be deleted)
5. **`test/debug_http_server3.dart`** - Debug script (can be deleted)

## Technical Details

### Why server.first Deadlocks

`server.first` is implemented as:
```dart
Future<HttpRequest> get first async {
  await for (var request in this) {
    return request;
  }
}
```

This blocks the current execution context waiting for a request. When combined with an `await` on the client side, you get:

```
Client thread: await response (blocked)
        ↓
Server thread: await server.first (blocked)
        ↓
DEADLOCK - both waiting for each other
```

### Why server.listen Works

`server.listen()` is non-blocking:
```dart
server.listen((request) {
  // This callback fires when request arrives
  // Doesn't block the current execution
});
```

The listener is set up immediately, then the client request proceeds asynchronously. When the request arrives, the callback fires and completes the Completer.

```
1. Set up listener (non-blocking)
2. Make client request (non-blocking with .then())
3. Request arrives → listener callback fires
4. Completer completes → test continues
✅ No deadlock!
```

## Alternative Approaches Considered

### Approach 1: Mock HttpRequest class
**Pros:** No real HTTP server needed
**Cons:** HttpRequest is complex, mocking all methods is error-prone

### Approach 2: Use package:http_mock
**Pros:** Existing solution
**Cons:** Another dependency, may not work with internal HttpRequest

### Approach 3: Use server.listen (chosen)
**Pros:** Uses real HttpRequest, no mocks, no extra dependencies
**Cons:** Requires understanding async patterns

## Best Practices

### DO
✅ Use `server.listen()` with `Completer` for mock requests
✅ Clean up servers after tests (`cleanupMockRequest`)
✅ Use `tearDownAll` to clean up remaining servers
✅ Test with real HttpRequest objects when possible

### DON'T
❌ Use `await server.first` in tests
❌ Await client request and server request simultaneously
❌ Forget to close servers (resource leak)
❌ Over-mock when real objects work fine

## Future Improvements

1. Add timeout to `createMockHttpRequest` for safety
2. Support custom HTTP methods (POST, PUT, etc.)
3. Support custom headers and body
4. Add helper for creating Request with specific data
5. Consider package for complex HTTP mocking scenarios

## Summary

**Problem:** HTTP server tests deadlocked with `server.first`
**Cause:** Circular await between client and server
**Solution:** Use `server.listen()` with `Completer`
**Result:** ✅ Tests pass in <1 second without timeouts

**Impact:** Can now write integration tests with real HTTP requests!
